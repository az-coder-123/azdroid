import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';
import 'package:desk_droid/features/discovery/domain/repositories/device_discovery_repository.dart';

/// Concrete implementation of [DeviceDiscoveryRepository].
class DeviceDiscoveryRepositoryImpl implements DeviceDiscoveryRepository {
  const DeviceDiscoveryRepositoryImpl({required this.datasource});

  final DeviceDiscoveryDatasource datasource;

  @override
  Future<List<DeviceEntity>> discoverDevices() async {
    try {
      final models = await datasource.scanDevices();
      return models;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to discover devices',
        error: e,
        stackTrace: stack,
      );
      return const [];
    }
  }

  @override
  Future<bool> connectDevice(DeviceEntity device) async {
    try {
      return await datasource.connect(device.ipAddress, device.port);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to connect device ${device.id}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> disconnectDevice(String deviceId) async {
    try {
      return await datasource.disconnect(deviceId);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to disconnect device $deviceId',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> pairDevice({
    required String ipAddress,
    required int port,
    required String pairingCode,
  }) async {
    try {
      return await datasource.pair(ipAddress, port, pairingCode);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to pair device at $ipAddress:$port',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> manualConnect({
    required String ipAddress,
    required int port,
  }) async {
    try {
      return await datasource.connect(ipAddress, port);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to manually connect to $ipAddress:$port',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> switchUsbToWifi(String serial, {int port = 5555}) async {
    try {
      return await datasource.switchUsbToWifi(serial, port: port);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to switch USB device $serial to Wi-Fi mode',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
