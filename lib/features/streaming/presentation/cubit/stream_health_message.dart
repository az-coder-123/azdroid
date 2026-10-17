import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';

/// User-facing guidance when the video stream is lost.
extension StreamHealthMessage on StreamHealth {
  /// Explains a terminal health on [deviceName], or `null` when the stream
  /// can still recover.
  String? messageFor(String deviceName) => switch (this) {
    StreamHealth.failed =>
      'No video was received from $deviceName.\n'
          'The mirroring server did not respond. Check the connection, '
          'then retry.',
    StreamHealth.ended =>
      'The video stream from $deviceName stopped.\n'
          'The device may have disconnected. Retry to reconnect.',
    StreamHealth.connecting || StreamHealth.live => null,
  };
}
