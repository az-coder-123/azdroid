import 'package:desk_droid/core/services/video_decoder_unavailable_exception.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/video_stream_start');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = VideoStreamNativeService(channel: channel);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void answerStartStream(Future<Object?> Function() reply) {
    messenger.setMockMethodCallHandler(channel, (call) {
      expect(call.method, 'startStream');
      return reply();
    });
  }

  group('VideoStreamNativeService.startStream', () {
    test('returns the texture id', () async {
      answerStartStream(() async => 42);

      expect(await service.startStream(), 42);
    });

    test('throws when the host has no video decoder', () {
      answerStartStream(
        () async => throw PlatformException(
          code: VideoDecoderUnavailableException.errorCode,
          message: 'Media Foundation is not installed',
        ),
      );

      expect(
        service.startStream(),
        throwsA(isA<VideoDecoderUnavailableException>()),
      );
    });

    test('returns null for other native errors', () async {
      answerStartStream(
        () async => throw PlatformException(code: 'NO_REGISTRY'),
      );

      expect(await service.startStream(), isNull);
    });
  });
}
