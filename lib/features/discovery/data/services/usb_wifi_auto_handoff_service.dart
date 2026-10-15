import 'package:desk_droid/core/models/adb_device.dart';
import 'package:desk_droid/core/services/adb_tcpip_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';

/// Contract for automatically provisioning Wi-Fi mode when an authorized USB device is attached.
abstract class UsbWifiAutoHandoffService {
  /// Evaluates attached USB devices and automatically enables TCP/IP mode and connects wirelessly.
  /// Returns `true` if any new device was provisioned.
  Future<bool> autoProvisionUsbDevices(List<AdbDevice> attachedDevices);
}

/// Production implementation tracking active USB serials to avoid redundant provisioning cycles.
class UsbWifiAutoHandoffServiceImpl implements UsbWifiAutoHandoffService {
  UsbWifiAutoHandoffServiceImpl({AdbTcpipService? adbTcpipService})
    : _tcpipService = adbTcpipService ?? AdbTcpipService();

  final AdbTcpipService _tcpipService;
  final Set<String> _provisionedSerials = <String>{};

  @override
  Future<bool> autoProvisionUsbDevices(List<AdbDevice> attachedDevices) async {
    final currentUsbSerials = attachedDevices
        .where((d) => d.isUsb)
        .map((d) => d.serial)
        .toSet();

    // Clean up unplugged devices so they can be re-provisioned if re-attached later
    _provisionedSerials.removeWhere((s) => !currentUsbSerials.contains(s));

    var anyProvisioned = false;

    for (final device in attachedDevices) {
      if (!device.isUsb || !device.isAuthorized) continue;
      if (_provisionedSerials.contains(device.serial)) continue;

      _provisionedSerials.add(device.serial);
      try {
        final result = await _tcpipService.switchUsbToWifi(device.serial);
        if (result.isSuccess) {
          anyProvisioned = true;
          AppLogger.info(
            'Auto-provisioned Wi-Fi mode for USB device: ${device.serial}',
          );
        }
      } catch (e) {
        AppLogger.debug('Auto-provisioning failed for ${device.serial}: $e');
      }
    }

    return anyProvisioned;
  }
}
