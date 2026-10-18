import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';

/// User-facing guidance for each [StreamStartFailure].
extension StreamStartFailureMessage on StreamStartFailure {
  /// Explains what went wrong on [deviceName] and how to fix it.
  String messageFor(String deviceName) => switch (this) {
    StreamStartFailure.deviceUnauthorized =>
      'USB debugging is not allowed on $deviceName yet.\n'
          'Unlock the phone and tap "Allow" on the "Allow USB debugging?" '
          'prompt, then retry. No prompt? Retry shows it again on Wi-Fi; '
          'on USB, replug the cable.',
    StreamStartFailure.deviceOffline =>
      '$deviceName is offline.\n'
          'Reconnect the cable or Wi-Fi connection, then retry.',
    StreamStartFailure.deviceNotFound =>
      '$deviceName is not connected to ADB.\n'
          'Reconnect it from the device list, then retry.',
    StreamStartFailure.serverStartFailed =>
      'Could not start the mirroring server on $deviceName.\n'
          'Check the ADB connection, then retry.',
    StreamStartFailure.controlConnectFailed =>
      'Connected to $deviceName, but the input channel did not open.\n'
          'Unlock the phone and retry. If it keeps failing, reconnect the '
          'device.',
    StreamStartFailure.audioConnectFailed =>
      'Connected to $deviceName, but the audio channel did not open.\n'
          'Retry. If it keeps failing, reconnect the device.',
    StreamStartFailure.decoderUnavailable =>
      'This computer cannot decode video: Windows N and KN editions ship '
          'without Media Foundation.\n'
          'Install the Media Feature Pack (Settings > Apps > Optional '
          'features), restart the computer, then retry.',
  };
}
