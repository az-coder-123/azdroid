import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';

/// User-facing guidance for each [StreamStartFailure].
extension StreamStartFailureMessage on StreamStartFailure {
  /// Explains what went wrong on [deviceName] and how to fix it.
  String messageFor(String deviceName) => switch (this) {
    StreamStartFailure.deviceUnauthorized =>
      'USB debugging is not allowed on $deviceName yet.\n'
          'Unlock the phone, tap "Allow" on the "Allow USB debugging?" '
          'prompt, then retry.',
    StreamStartFailure.deviceOffline =>
      '$deviceName is offline.\n'
          'Reconnect the cable or Wi-Fi connection, then retry.',
    StreamStartFailure.deviceNotFound =>
      '$deviceName is not connected to ADB.\n'
          'Reconnect it from the device list, then retry.',
    StreamStartFailure.serverStartFailed =>
      'Could not start the mirroring server on $deviceName.\n'
          'Check the ADB connection, then retry.',
  };
}
