import 'package:desk_droid/core/models/native_audio_stats.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/audio_stream');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'a missing plugin means no audio, so the server runs without it',
    () async {
      final service = AudioStreamNativeService(channel: channel);

      expect(await service.isAvailable(), isFalse);
      expect(await service.startAudio(), isFalse);
      expect(await service.getStats(), isNull);
    },
  );

  test('calls the contract methods with their arguments', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getAudioStats' => {
          'state': 'playing',
          'bytesReceived': 4096,
          'bufferedFrames': 4800,
          'playedFrames': 96000,
          'droppedFrames': 0,
          'underruns': 1,
        },
        _ => true,
      };
    });
    final service = AudioStreamNativeService(channel: channel);

    expect(await service.isAvailable(), isTrue);
    expect(await service.startAudio(host: '127.0.0.1', port: 27183), isTrue);
    await service.setVolume(0.5);
    await service.setMuted(true);
    final stats = await service.getStats();
    await service.stopAudio();

    expect(calls.map((c) => c.method), [
      'isAvailable',
      'startAudio',
      'setVolume',
      'setMuted',
      'getAudioStats',
      'stopAudio',
    ]);
    expect(calls[1].arguments, {'host': '127.0.0.1', 'port': 27183});
    expect(calls[2].arguments, {'volume': 0.5});
    expect(calls[3].arguments, {'muted': true});
    expect(stats!.state, NativeAudioState.playing);
    expect(stats.bufferedMs, 100);
    expect(stats.underruns, 1);
  });

  test('unknown state names do not break parsing', () {
    final stats = NativeAudioStats.fromMap(const {'state': 'warming_up'});

    expect(stats.state, NativeAudioState.unknown);
    expect(stats.bytesReceived, 0);
  });

  test('a platform error is logged, not thrown', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'BOOM'),
    );
    final service = AudioStreamNativeService(channel: channel);

    expect(await service.startAudio(), isFalse);
    await service.setVolume(1);
  });
}
