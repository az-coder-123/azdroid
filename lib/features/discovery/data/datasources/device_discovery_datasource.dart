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

    // 1. Process attached devices with USB/Wi-Fi deduplication
    final usbDevices = attached.where((d) => d.isUsb).toList();
    final wifiDevices = attached.where((d) => !d.isUsb).toList();
    final matchedUsbSerials = <String>{};

    for (final wifi in wifiDevices) {
      final parts = wifi.serial.split(':');
      final ip = parts[0];
      final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 5555) : 5555;
      final hwSerial = await _tcpipService.getHardwareSerial(wifi.serial);

      AdbDevice? matchedUsb;
      for (final usb in usbDevices) {
        if (matchedUsbSerials.contains(usb.serial)) continue;
        if (hwSerial != null && usb.serial == hwSerial) {
          matchedUsb = usb;
          break;
        } else if (hwSerial == null &&
            usb.model != null &&
            usb.model == wifi.model &&
            usb.product != null &&
            usb.product == wifi.product) {
          matchedUsb = usb;
          break;
        }
      }

      if (matchedUsb != null) {
        matchedUsbSerials.add(matchedUsb.serial);
        final name = wifi.model ?? matchedUsb.model ?? wifi.serial;
        deviceMap[wifi.serial] = DeviceModel(
          id: wifi.serial,
          name: name,
          ipAddress: ip,
          port: port,
          connectionType: DeviceConnectionType.dual,
          isConnected: wifi.isAuthorized && matchedUsb.isAuthorized,
          isUnauthorized: wifi.isUnauthorized || matchedUsb.isUnauthorized,
          requiresPairing: false,
          model: wifi.model ?? matchedUsb.model,
          usbSerial: matchedUsb.serial,
          wirelessSerial: wifi.serial,
        );
      } else {
        final name = wifi.model ?? wifi.product ?? wifi.serial;
        deviceMap[wifi.serial] = DeviceModel(
          id: wifi.serial,
          name: name,
          ipAddress: ip,
          port: port,
          connectionType: DeviceConnectionType.wireless,
          isConnected: wifi.isAuthorized,
          isUnauthorized: wifi.isUnauthorized,
          requiresPairing: false,
          model: wifi.model,
          wirelessSerial: wifi.serial,
        );
      }
    }

    for (final usb in usbDevices) {
      if (matchedUsbSerials.contains(usb.serial)) continue;
      final name = usb.model ?? usb.product ?? usb.serial;
      deviceMap[usb.serial] = DeviceModel(
        id: usb.serial,
        name: name,
        ipAddress: '127.0.0.1',
        port: 5555,
        connectionType: DeviceConnectionType.usb,
        isConnected: usb.isAuthorized,
        isUnauthorized: usb.isUnauthorized,
        requiresPairing: false,
        model: usb.model,
        usbSerial: usb.serial,
      );
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
