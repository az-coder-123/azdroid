import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/control/data/services/native_video_frame_size_source.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNativeService extends Mock implements IVideoStreamNativeService {}

void main() {
  late MockNativeService native;
  setUp(() => native = MockNativeService());

  test('returns the decoded video size', () async {
    when(() => native.getDimensions())
        .thenAnswer((_) async => {'width': 2336, 'height': 1080});
    expect(
      await NativeVideoFrameSizeSource(native).current(),
      const FrameSize(2336, 1080),
    );
  });

  test('returns null before the first frame (0x0)', () async {
    when(() => native.getDimensions())
        .thenAnswer((_) async => {'width': 0, 'height': 0});
    expect(await NativeVideoFrameSizeSource(native).current(), isNull);
  });
}
