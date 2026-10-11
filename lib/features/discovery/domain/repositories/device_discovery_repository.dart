import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Contract defining the device discovery and connectivity operations.
abstract class DeviceDiscoveryRepository {
  /// Scans the local network subnet and USB ports for available Android devices.
  Future<List<DeviceEntity>> discoverDevices();

  /// Initiates a connection session to the specified [device].
  Future<bool> connectDevice(DeviceEntity device);

  /// Terminates an active connection session with the device identified by [deviceId].
  Future<bool> disconnectDevice(String deviceId);
}
