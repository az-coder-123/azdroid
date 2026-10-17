import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_telemetry_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamTelemetryLabels', () {
    test('shows a dash instead of a made-up value when unknown', () {
      const waiting = StreamTelemetry(health: StreamHealth.connecting);

      for (final telemetry in [null, waiting]) {
        expect(StreamTelemetryLabels.latency(telemetry), '— ms');
        expect(StreamTelemetryLabels.fps(telemetry), '— FPS');
        expect(StreamTelemetryLabels.bitrate(telemetry), '— Mbps');
      }
    });

    test('formats measured values', () {
      const telemetry = StreamTelemetry(
        health: StreamHealth.live,
        fps: 59.6,
        bitrateMbps: 7.84,
        latencyMs: 12.4,
      );

      expect(StreamTelemetryLabels.latency(telemetry), '12ms');
      expect(StreamTelemetryLabels.fps(telemetry), '60 FPS');
      expect(StreamTelemetryLabels.bitrate(telemetry), '7.8 Mbps');
    });

    test('shows sub-millisecond latency as <1ms', () {
      const telemetry = StreamTelemetry(
        health: StreamHealth.live,
        latencyMs: 0.4,
      );

      expect(StreamTelemetryLabels.latency(telemetry), '<1ms');
    });
  });
}
