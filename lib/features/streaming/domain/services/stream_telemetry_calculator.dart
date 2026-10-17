import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';

/// Turns two cumulative native snapshots into per-second telemetry.
class StreamTelemetryCalculator {
  const StreamTelemetryCalculator();

  static const int _bitsPerByte = 8;
  static const double _bitsPerMegabit = 1000000;
  static const double _microsecondsPerMillisecond = 1000;

  /// Computes telemetry for [current], using [previous] taken [elapsed] ago.
  ///
  /// Returns health only (no rates) for the first sample, a non-positive
  /// [elapsed], or counters that went backwards (a new native session).
  StreamTelemetry calculate({
    required NativeStreamStats? previous,
    required NativeStreamStats current,
    required Duration elapsed,
  }) {
    final health = healthOf(current.state);
    if (previous == null || elapsed <= Duration.zero) {
      return StreamTelemetry(health: health);
    }

    final frames = current.framesDecoded - previous.framesDecoded;
    final bytes = current.bytesReceived - previous.bytesReceived;
    final processingUs = current.processingTimeUs - previous.processingTimeUs;
    if (frames < 0 || bytes < 0 || processingUs < 0) {
      return StreamTelemetry(health: health);
    }

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    return StreamTelemetry(
      health: health,
      fps: frames / seconds,
      bitrateMbps: bytes * _bitsPerByte / seconds / _bitsPerMegabit,
      latencyMs: frames > 0
          ? processingUs / frames / _microsecondsPerMillisecond
          : null,
    );
  }

  /// Maps a native state to stream health. `idle` and unknown names count as
  /// connecting, since the stream has just been (re)started.
  static StreamHealth healthOf(NativeStreamState state) => switch (state) {
    NativeStreamState.streaming => StreamHealth.live,
    NativeStreamState.failed => StreamHealth.failed,
    NativeStreamState.ended => StreamHealth.ended,
    NativeStreamState.idle ||
    NativeStreamState.connecting ||
    NativeStreamState.unknown => StreamHealth.connecting,
  };
}
