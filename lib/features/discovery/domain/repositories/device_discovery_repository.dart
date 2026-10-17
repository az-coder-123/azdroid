import 'package:desk_droid/core/models/device_entity.dart';

/// Contract defining the device discovery, connectivity, and pairing operations.
abstract class DeviceDiscoveryRepository {
  /// Scans the local network subnet and USB ports for available Android devices and mDNS services.
  Future<List<DeviceEntity>> discoverDevices();

  /// Initiates a connection session to the specified [device].
  Future<bool> connectDevice(DeviceEntity device);

  /// Terminates an active connection session with the device identified by [deviceId].
  Future<bool> disconnectDevice(String deviceId);

  /// Pairs an Android 11+ device using wireless debugging pairing credentials.
  Future<bool> pairDevice({
    required String ipAddress,
    required int port,
    required String pairingCode,
  });

  /// Connects directly to an Android device via explicit IP and port.
  Future<bool> manualConnect({required String ipAddress, required int port});

  /// Switches an attached USB device to wireless TCP/IP mode on [port] (default 5555).
  Future<bool> switchUsbToWifi(String serial, {int port = 5555});
}
