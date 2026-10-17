import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';

/// Formats measured telemetry for badges. Unknown values show a dash instead
/// of a made-up number.
abstract final class StreamTelemetryLabels {
  static const String unknown = '—';

  /// Explains what the latency badge measures.
  static const String latencyTooltip =
      'Host processing time per frame (receive to display). '
      'Excludes device encoding and network time.';

  static String latency(StreamTelemetry? telemetry) {
    final ms = telemetry?.latencyMs;
    if (ms == null) return '$unknown ms';
    return ms < 1 ? '<1ms' : '${ms.round()}ms';
  }

  static String fps(StreamTelemetry? telemetry) {
    final fps = telemetry?.fps;
    return fps == null ? '$unknown FPS' : '${fps.round()} FPS';
  }

  static String bitrate(StreamTelemetry? telemetry) {
    final mbps = telemetry?.bitrateMbps;
    return mbps == null ? '$unknown Mbps' : '${mbps.toStringAsFixed(1)} Mbps';
  }
}
