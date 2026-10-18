import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/repositories/control_repository_impl.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/domain/repositories/video_frame_size_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockControlDatasource extends Mock implements ControlDatasource {}

class MockVideoFrameSizeSource extends Mock implements VideoFrameSizeSource {}

void main() {
  late MockControlDatasource mockDatasource;
  late ControlRepositoryImpl repository;

  const testSerial = '192.168.1.100:5555';
  const frame1080x2400 = FrameSize(1080, 2400);

  setUpAll(() => registerFallbackValue(const FrameSize(1, 1)));

  setUp(() {
    mockDatasource = MockControlDatasource();
    repository = ControlRepositoryImpl(datasource: mockDatasource);
  });

  group('ControlRepositoryImpl', () {
    test('sendTap converts normalized coordinates to pixels and delegates to datasource', () async {
      when(
        () => mockDatasource.injectTap(
          testSerial,
          540,
          1200,
          frame: frame1080x2400,
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.sendTap(
        testSerial,
        normalizedX: 0.5,
        normalizedY: 0.5,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.injectTap(
          testSerial,
          540,
          1200,
          frame: frame1080x2400,
        ),
      ).called(1);
    });

    test('sendSwipe converts coordinates and calls injectSwipe', () async {
      when(
        () => mockDatasource.injectSwipe(
          testSerial,
          108,
          240,
          540,
          1200,
          150,
          frame: frame1080x2400,
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.sendSwipe(
        testSerial,
        startX: 0.1,
        startY: 0.1,
        endX: 0.5,
        endY: 0.5,
        durationMs: 150,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.injectSwipe(
          testSerial,
          108,
          240,
          540,
          1200,
          150,
          frame: frame1080x2400,
        ),
      ).called(1);
    });

    test('sendScroll converts wheel delta into swipe coordinates', () async {
      when(
        () => mockDatasource.injectSwipe(
          testSerial,
          any(),
          any(),
          any(),
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.sendScroll(
        testSerial,
        normalizedX: 0.5,
        normalizedY: 0.5,
        deltaX: 0.0,
        deltaY: 50.0,
        displayWidth: 1080,
        displayHeight: 2400,
      );

      expect(result, isTrue);
      verify(
        () => mockDatasource.injectSwipe(
          testSerial,
          540,
          1200,
          540,
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      ).called(1);
    });

    test(
      'sendNavigationAction maps navigation actions to Android keycodes',
      () async {
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeBack,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeHome,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeAppSwitch,
          ),
        ).thenAnswer((_) async => true);

        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.back,
          ),
          isTrue,
        );
        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.home,
          ),
          isTrue,
        );
        expect(
          await repository.sendNavigationAction(
            testSerial,
            NavigationAction.appSwitch,
          ),
          isTrue,
        );

        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeBack,
          ),
        ).called(1);
        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeHome,
          ),
        ).called(1);
        verify(
          () => mockDatasource.injectKeyevent(
            testSerial,
            AndroidKeyCodes.keycodeAppSwitch,
          ),
        ).called(1);
      },
    );

    test('sendText delegates to datasource.injectText', () async {
      when(() => mockDatasource.injectText(testSerial, 'Xin chào'))
          .thenAnswer((_) async => true);

      final result = await repository.sendText(testSerial, 'Xin chào');

      expect(result, isTrue);
      verify(() => mockDatasource.injectText(testSerial, 'Xin chào')).called(1);
    });

    group('frame size', () {
      late MockVideoFrameSizeSource frameSource;

      setUp(() {
        frameSource = MockVideoFrameSizeSource();
        repository = ControlRepositoryImpl(
          datasource: mockDatasource,
          frameSizeSource: frameSource,
        );
        when(
          () => mockDatasource.injectTap(
            any(),
            any(),
            any(),
            frame: any(named: 'frame'),
          ),
        ).thenAnswer((_) async => true);
      });

      test('maps taps onto the live video frame and passes it on', () async {
        // Landscape board: the old fixed 1080x2400 mapping missed by far.
        when(() => frameSource.current())
            .thenAnswer((_) async => const FrameSize(1920, 1080));

        await repository.sendTap(
          testSerial,
          normalizedX: 0.5,
          normalizedY: 0.25,
        );

        verify(
          () => mockDatasource.injectTap(
            testSerial,
            960,
            270,
            frame: const FrameSize(1920, 1080),
          ),
        ).called(1);
      });

      test('explicit display size wins over the live frame', () async {
        when(() => frameSource.current())
            .thenAnswer((_) async => const FrameSize(1920, 1080));

        await repository.sendTap(
          testSerial,
          normalizedX: 0.5,
          normalizedY: 0.5,
          displayWidth: 1080,
          displayHeight: 2340,
        );

        verify(
          () => mockDatasource.injectTap(
            testSerial,
            540,
            1170,
            frame: const FrameSize(1080, 2340),
          ),
        ).called(1);
      });

      test(
        'falls back to default size without video, passing no frame',
        () async {
          when(() => frameSource.current()).thenAnswer((_) async => null);

          await repository.sendTap(
            testSerial,
            normalizedX: 0.5,
            normalizedY: 0.5,
          );

          verify(() => mockDatasource.injectTap(testSerial, 540, 1200))
              .called(1);
        },
      );
    });
  });
}
