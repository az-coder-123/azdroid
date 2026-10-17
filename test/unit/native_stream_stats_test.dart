import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeStreamStats.fromMap', () {
    test('parses the getStats payload', () {
      final stats = NativeStreamStats.fromMap(const {
        'state': 'streaming',
        'framesDecoded': 120,
        'bytesReceived': 2048,
        'processingTimeUs': 960000,
      });

      expect(
        stats,
        const NativeStreamStats(
          state: NativeStreamState.streaming,
          framesDecoded: 120,
          bytesReceived: 2048,
          processingTimeUs: 960000,
        ),
      );
    });

    test('tolerates unknown states and missing counters', () {
      final stats = NativeStreamStats.fromMap(const {'state': 'warming_up'});

      expect(stats.state, NativeStreamState.unknown);
      expect(stats.framesDecoded, 0);
      expect(stats.bytesReceived, 0);
      expect(stats.processingTimeUs, 0);
    });
  });

  group('VideoStreamNativeService.getStats', () {
    const channel = MethodChannel('test/video_stream');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final service = VideoStreamNativeService(channel: channel);

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('reads stats from the channel', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getStats');
        return {'state': 'ended', 'framesDecoded': 5};
      });

      final stats = await service.getStats();

      expect(stats?.state, NativeStreamState.ended);
      expect(stats?.framesDecoded, 5);
    });

    test('returns null when the native side has no getStats', () async {
      // No handler registered: the channel throws MissingPluginException.
      expect(await service.getStats(), isNull);
    });
  });
}
