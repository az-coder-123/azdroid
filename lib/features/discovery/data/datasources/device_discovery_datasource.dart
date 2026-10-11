import 'package:wifi_desk/features/discovery/data/models/device_model.dart';

/// Low-level data source interface for scanning and pinging Android endpoints.
abstract class DeviceDiscoveryDatasource {
  /// Queries ADB and scans the local Wi-Fi subnet.
  Future<List<DeviceModel>> scanDevices();

  /// Establishes the low-level ADB TCP transport connection.
  Future<bool> connect(String ipAddress, int port);

  /// Closes the ADB transport connection.
  Future<bool> disconnect(String ipAddress, int port);
}

/// Default implementation providing mock and standard ADB device enumeration.
class DeviceDiscoveryDatasourceImpl implements DeviceDiscoveryDatasource {
  const DeviceDiscoveryDatasourceImpl();

  @override
  Future<List<DeviceModel>> scanDevices() async {
    // Simulated discovery delay representing network & ADB probe latency
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Return empty list by default until physical/simulated device is paired
    return const [];
  }

  @override
  Future<bool> connect(String ipAddress, int port) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> disconnect(String ipAddress, int port) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return true;
  }
}
