import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
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
  ///
  /// For an unauthorized Wi-Fi device it first reconnects, so the phone
  /// shows the "Allow USB debugging?" prompt again: the phone asks only when
  /// a connection opens, and the first prompt often appears (and times out)
  /// while nobody is looking, for example during auto-discovery.
  Future<void> ensureReady(String serial) async {
    final devices = await _adbService.getAttachedDevices();
    final device = devices.where((entry) => entry.serial == serial).firstOrNull;
    final failure = failureFor(device);
    if (failure == null) return;
    if (failure == StreamStartFailure.deviceUnauthorized) {
      await _requestAuthorizationAgain(serial);
    }
    throw StreamStartException(failure, deviceSerial: serial);
  }

  /// Reopens a Wi-Fi (`ip:port`) connection to trigger a new prompt.
  /// USB devices prompt again when replugged, so they are left alone.
  Future<void> _requestAuthorizationAgain(String serial) async {
    final endpoint = wifiEndpointOf(serial);
    if (endpoint == null) return;
    AppLogger.info('Reconnecting $serial so the phone asks to allow it again');
    await _adbService.disconnect(serial);
    await _adbService.connect(endpoint.host, endpoint.port);
  }

  /// `(host, port)` for an `ip:port` serial, or `null` for USB and mDNS
  /// serials.
  static ({String host, int port})? wifiEndpointOf(String serial) {
    final separator = serial.lastIndexOf(':');
    if (separator <= 0) return null;
    final port = int.tryParse(serial.substring(separator + 1));
    if (port == null) return null;
    return (host: serial.substring(0, separator), port: port);
  }

  /// Maps an ADB device entry to a start failure, or `null` when it is ready.
  static StreamStartFailure? failureFor(AdbDevice? device) {
    if (device == null) return StreamStartFailure.deviceNotFound;
    if (device.isAuthorized) return null;
    if (device.isUnauthorized) return StreamStartFailure.deviceUnauthorized;
    return StreamStartFailure.deviceOffline;
  }
}
