import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/services/stream_telemetry_sampler.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVideoStreamNativeService extends Mock
    implements IVideoStreamNativeService {}

void main() {
  late MockVideoStreamNativeService nativeService;
  late StreamTelemetrySampler sampler;

  setUp(() {
    nativeService = MockVideoStreamNativeService();
    sampler = StreamTelemetrySampler(
      nativeService: nativeService,
      interval: const Duration(milliseconds: 5),
    );
  });

  /// Answers successive `getStats` calls with [responses], then repeats the
  /// last one.
  void stubStats(List<NativeStreamStats?> responses) {
    var call = 0;
    when(() => nativeService.getStats()).thenAnswer((_) async {
      final index = call < responses.length ? call : responses.length - 1;
      call++;
      return responses[index];
    });
  }

  test('emits health first, then measured rates', () async {
    stubStats(const [
      NativeStreamStats(state: NativeStreamState.connecting),
      NativeStreamStats(
        state: NativeStreamState.streaming,
        framesDecoded: 3,
        bytesReceived: 3000,
        processingTimeUs: 30000,
      ),
    ]);

    final samples = await sampler.watch().take(2).toList();

    expect(
      samples.first,
      const StreamTelemetry(health: StreamHealth.connecting),
    );
    expect(samples.last.health, StreamHealth.live);
    expect(samples.last.fps, greaterThan(0));
    expect(samples.last.bitrateMbps, greaterThan(0));
    expect(samples.last.latencyMs, 10);
  });

  test('skips samples the native side cannot provide', () async {
    stubStats(const [
      null,
      null,
      NativeStreamStats(state: NativeStreamState.failed),
    ]);

    final first = await sampler.watch().first;

    expect(first, const StreamTelemetry(health: StreamHealth.failed));
    verify(() => nativeService.getStats()).called(3);
  });
}
