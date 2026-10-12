import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/features/discovery/data/models/device_model.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Low-level data source interface for scanning and pinging Android endpoints.
abstract class DeviceDiscoveryDatasource {
  /// Queries ADB and scans the local Wi-Fi subnet for devices and mDNS services.
  Future<List<DeviceModel>> scanDevices();

  /// Establishes the low-level ADB TCP transport connection.
  Future<bool> connect(String ipAddress, int port);

  /// Closes the ADB transport connection for the given target (serial or ip:port).
  Future<bool> disconnect(String target);

  /// Pairs with an Android 11+ device using wireless debugging pairing code.
  Future<bool> pair(String ipAddress, int port, String pairingCode);

  /// Switches a USB device to wireless mode on [port] (default 5555).
  Future<bool> switchUsbToWifi(String serial, {int port = 5555});
}

/// Production implementation leveraging [AdbService] to scan attached and mDNS devices.
class DeviceDiscoveryDatasourceImpl implements DeviceDiscoveryDatasource {
  const DeviceDiscoveryDatasourceImpl({this.adbService, this.adbTcpipService});

  final AdbService? adbService;
  final AdbTcpipService? adbTcpipService;

  AdbService get _service => adbService ?? AdbService();
  AdbTcpipService get _tcpipService =>
      adbTcpipService ?? AdbTcpipService(adbService: _service);

  @override
  Future<List<DeviceModel>> scanDevices() async {
    final attachedFuture = _service.getAttachedDevices();
    final mdnsFuture = _service.getMdnsServices();

    final results = await Future.wait([attachedFuture, mdnsFuture]);
    final attached = results[0] as List<AdbDevice>;
    final mdnsServices = results[1] as List<AdbMdnsService>;

    final deviceMap = <String, DeviceModel>{};

    // 1. Process attached devices from `adb devices -l`
    for (final device in attached) {
      final isUsb = device.isUsb;
      String ip = '127.0.0.1';
      int port = 5555;

      if (!isUsb && device.serial.contains(':')) {
        final parts = device.serial.split(':');
        ip = parts[0];
        port = int.tryParse(parts[1]) ?? 5555;
      }

      final deviceName = device.model ?? device.product ?? device.serial;

      final model = DeviceModel(
        id: device.serial,
        name: deviceName,
        ipAddress: ip,
        port: port,
        connectionType: isUsb
            ? DeviceConnectionType.usb
            : DeviceConnectionType.wireless,
        isConnected: device.isAuthorized,
        isUnauthorized: device.isUnauthorized,
        requiresPairing: false,
        model: device.model,
      );

      deviceMap[device.serial] = model;
    }

    // 2. Process discovered mDNS services
    for (final service in mdnsServices) {
      final key = '${service.ipAddress}:${service.port}';

      if (service.isPairingService) {
        // Look for an existing device on the same IP
        final existingKey = deviceMap.keys.firstWhere(
          (k) => k.startsWith('${service.ipAddress}:'),
          orElse: () => '',
        );

        if (existingKey.isNotEmpty) {
          final existing = deviceMap[existingKey]!;
          deviceMap[existingKey] = DeviceModel(
            id: existing.id,
            name: existing.name,
            ipAddress: existing.ipAddress,
            port: existing.port,
            connectionType: existing.connectionType,
            isConnected: existing.isConnected,
            isUnauthorized: existing.isUnauthorized,
            requiresPairing: true,
            pairingPort: service.port,
            batteryLevel: existing.batteryLevel,
            model: existing.model,
          );
        } else {
          // New device discovered in pairing mode
          deviceMap[key] = DeviceModel(
            id: key,
            name: service.serviceName.isNotEmpty
                ? service.serviceName
                : 'Android Device',
            ipAddress: service.ipAddress,
            port: 5555,
            connectionType: DeviceConnectionType.wireless,
            isConnected: false,
            isUnauthorized: false,
            requiresPairing: true,
            pairingPort: service.port,
          );
        }
      } else if (service.isConnectService) {
        // Ready-to-connect mDNS service
        if (!deviceMap.containsKey(key)) {
          deviceMap[key] = DeviceModel(
            id: key,
            name: service.serviceName.isNotEmpty
                ? service.serviceName
                : 'Android Device',
            ipAddress: service.ipAddress,
            port: service.port,
            connectionType: DeviceConnectionType.wireless,
            isConnected: false,
            isUnauthorized: false,
            requiresPairing: false,
          );
        }
      }
    }

    return deviceMap.values.toList();
  }

  @override
  Future<bool> connect(String ipAddress, int port) async {
    final result = await _service.connect(ipAddress, port);
    return result.isSuccess;
  }

  @override
  Future<bool> disconnect(String target) async {
    final result = await _service.disconnect(target);
    return result.isSuccess;
  }

  @override
  Future<bool> pair(String ipAddress, int port, String pairingCode) async {
    final result = await _service.pair(ipAddress, port, pairingCode);
    return result.isSuccess;
  }

  @override
  Future<bool> switchUsbToWifi(String serial, {int port = 5555}) async {
    final result = await _tcpipService.switchUsbToWifi(serial, port: port);
    return result.isSuccess;
  }
}
