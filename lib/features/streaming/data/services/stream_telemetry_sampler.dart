import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/services/stream_telemetry_calculator.dart';

/// Polls the native `getStats` method and emits measured telemetry.
///
/// Polling (rather than an event channel) keeps the native side free of
/// platform-thread hand-offs: it only exposes thread-safe counters.
class StreamTelemetrySampler {
  StreamTelemetrySampler({
    required this.nativeService,
    this.interval = defaultInterval,
    this.calculator = const StreamTelemetryCalculator(),
  });

  /// How often the header refreshes; also the averaging window for rates.
  static const Duration defaultInterval = Duration(seconds: 1);

  final IVideoStreamNativeService nativeService;
  final StreamTelemetryCalculator calculator;
  final Duration interval;

  /// Emits one [StreamTelemetry] per [interval] until the listener cancels.
  /// Samples the native side cannot provide are skipped.
  Stream<StreamTelemetry> watch() async* {
    NativeStreamStats? previous;
    final sinceLastSample = Stopwatch()..start();

    await for (final _ in Stream<void>.periodic(interval)) {
      final current = await nativeService.getStats();
      if (current == null) continue;

      final elapsed = sinceLastSample.elapsed;
      sinceLastSample.reset();
      final size = await nativeService.getDimensions();
      yield calculator
          .calculate(previous: previous, current: current, elapsed: elapsed)
          .withVideoSize(size['width'] ?? 0, size['height'] ?? 0);
      previous = current;
    }
  }
}
