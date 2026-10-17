import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';

/// Checks that ADB can reach an authorized device before streaming starts.
///
/// Without this check an unauthorized device produces a black viewport:
/// the scrcpy server never runs, but the native decoder still returns a
/// texture and keeps retrying the socket in the background.
class StreamDevicePreflight {
  StreamDevicePreflight({AdbService? adbService})
    : _adbService = adbService ?? AdbService();

  final AdbService _adbService;

  /// Throws [StreamStartException] when [serial] is missing, offline, or
  /// waiting for the user to allow USB debugging.
  Future<void> ensureReady(String serial) async {
    final devices = await _adbService.getAttachedDevices();
    final device = devices.where((entry) => entry.serial == serial).firstOrNull;
    final failure = failureFor(device);
    if (failure != null) {
      throw StreamStartException(failure, deviceSerial: serial);
    }
  }

  /// Maps an ADB device entry to a start failure, or `null` when it is ready.
  static StreamStartFailure? failureFor(AdbDevice? device) {
    if (device == null) return StreamStartFailure.deviceNotFound;
    if (device.isAuthorized) return null;
    if (device.isUnauthorized) return StreamStartFailure.deviceUnauthorized;
    return StreamStartFailure.deviceOffline;
  }
}
