import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/services/stream_telemetry_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = StreamTelemetryCalculator();
  const oneSecond = Duration(seconds: 1);

  NativeStreamStats stats({
    NativeStreamState state = NativeStreamState.streaming,
    int frames = 0,
    int bytes = 0,
    int processingUs = 0,
  }) => NativeStreamStats(
    state: state,
    framesDecoded: frames,
    bytesReceived: bytes,
    processingTimeUs: processingUs,
  );

  group('StreamTelemetryCalculator.calculate', () {
    test('reports health only for the first sample', () {
      final telemetry = calculator.calculate(
        previous: null,
        current: stats(frames: 30),
        elapsed: oneSecond,
      );

      expect(telemetry, const StreamTelemetry(health: StreamHealth.live));
    });

    test('derives rates from the difference between two samples', () {
      final telemetry = calculator.calculate(
        previous: stats(frames: 100, bytes: 1000000, processingUs: 500000),
        current: stats(frames: 160, bytes: 2000000, processingUs: 1100000),
        elapsed: oneSecond,
      );

      expect(telemetry.fps, 60);
      expect(telemetry.bitrateMbps, 8); // 1,000,000 bytes * 8 bits / 1 s.
      expect(telemetry.latencyMs, 10); // 600,000 us / 60 frames.
    });

    test('scales rates by the real elapsed time', () {
      final telemetry = calculator.calculate(
        previous: stats(frames: 0),
        current: stats(frames: 60),
        elapsed: const Duration(seconds: 2),
      );

      expect(telemetry.fps, 30);
    });

    test('leaves latency unknown when no frame was decoded', () {
      final telemetry = calculator.calculate(
        previous: stats(frames: 10, bytes: 100),
        current: stats(frames: 10, bytes: 100),
        elapsed: oneSecond,
      );

      expect(telemetry.fps, 0);
      expect(telemetry.latencyMs, isNull);
    });

    test('skips rates when counters go backwards (new native session)', () {
      final telemetry = calculator.calculate(
        previous: stats(frames: 500),
        current: stats(frames: 3),
        elapsed: oneSecond,
      );

      expect(telemetry.fps, isNull);
      expect(telemetry.bitrateMbps, isNull);
    });
  });

  group('StreamTelemetry.withVideoSize', () {
    const live = StreamTelemetry(health: StreamHealth.live, fps: 30);

    test('adds a known size and keeps the other values', () {
      final sized = live.withVideoSize(1080, 2336);

      expect(sized.videoWidth, 1080);
      expect(sized.videoHeight, 2336);
      expect(sized.fps, 30);
    });

    test('ignores an unknown (zero) size', () {
      expect(live.withVideoSize(0, 0), live);
    });
  });

  group('StreamTelemetryCalculator.healthOf', () {
    test('maps native states to stream health', () {
      expect(
        StreamTelemetryCalculator.healthOf(NativeStreamState.streaming),
        StreamHealth.live,
      );
      expect(
        StreamTelemetryCalculator.healthOf(NativeStreamState.failed),
        StreamHealth.failed,
      );
      expect(
        StreamTelemetryCalculator.healthOf(NativeStreamState.ended),
        StreamHealth.ended,
      );
      for (final waiting in [
        NativeStreamState.idle,
        NativeStreamState.connecting,
        NativeStreamState.connected,
        NativeStreamState.unknown,
      ]) {
        expect(
          StreamTelemetryCalculator.healthOf(waiting),
          StreamHealth.connecting,
        );
      }
    });
  });
}
