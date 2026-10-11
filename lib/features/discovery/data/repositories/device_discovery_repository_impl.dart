import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';

/// Concrete implementation of [DeviceDiscoveryRepository].
class DeviceDiscoveryRepositoryImpl implements DeviceDiscoveryRepository {
  const DeviceDiscoveryRepositoryImpl({required this.datasource});

  final DeviceDiscoveryDatasource datasource;

  @override
  Future<List<DeviceEntity>> discoverDevices() async {
    try {
      final models = await datasource.scanDevices();
      return models;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> connectDevice(DeviceEntity device) async {
    try {
      return await datasource.connect(device.ipAddress, device.port);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> disconnectDevice(String deviceId) async {
    try {
      return await datasource.disconnect(deviceId);
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
      return false;
    }
  }
}
