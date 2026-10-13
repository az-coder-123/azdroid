import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';

class MockScreenshotRepository extends Mock implements ScreenshotRepository {}

void main() {
  late MockScreenshotRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  final testScreenshot = ScreenshotEntity(
    filePath: '/Users/mac/Downloads/WifiDesk_Screenshot_20261013_183000.png',
    fileName: 'WifiDesk_Screenshot_20261013_183000.png',
    fileSizeBytes: 245000,
    capturedAt: DateTime(2026, 10, 13, 18, 30),
    copiedToClipboard: true,
  );

  setUp(() {
    mockRepository = MockScreenshotRepository();
  });

  group('ScreenshotCubit', () {
    test('initial state is ScreenshotInitial', () {
      final cubit = ScreenshotCubit(repository: mockRepository);
      expect(cubit.state, isA<ScreenshotInitial>());
      cubit.close();
    });

    blocTest<ScreenshotCubit, ScreenshotState>(
      'captureScreenshot emits [ScreenshotCapturing, ScreenshotSuccess] when successful',
      build: () {
        when(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            customSaveDirectory: any(named: 'customSaveDirectory'),
          ),
        ).thenAnswer((_) async => testScreenshot);
        return ScreenshotCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.captureScreenshot(testSerial),
      expect: () => [
        isA<ScreenshotCapturing>(),
        isA<ScreenshotSuccess>().having(
          (s) => s.screenshot.fileName,
          'fileName',
          'WifiDesk_Screenshot_20261013_183000.png',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.captureScreenshot(deviceSerial: testSerial))
            .called(1);
      },
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'captureScreenshot emits [ScreenshotCapturing, ScreenshotFailure] when repository returns null',
      build: () {
        when(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            customSaveDirectory: any(named: 'customSaveDirectory'),
          ),
        ).thenAnswer((_) async => null);
        return ScreenshotCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.captureScreenshot(testSerial),
      expect: () => [
        isA<ScreenshotCapturing>(),
        isA<ScreenshotFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'No screenshot data received',
        ),
      ],
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'captureScreenshot emits [ScreenshotCapturing, ScreenshotFailure] when exception occurs',
      build: () {
        when(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            customSaveDirectory: any(named: 'customSaveDirectory'),
          ),
        ).thenThrow(Exception('ADB screencap failed'));
        return ScreenshotCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.captureScreenshot(testSerial),
      expect: () => [
        isA<ScreenshotCapturing>(),
        isA<ScreenshotFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          contains('ADB screencap failed'),
        ),
      ],
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'startAreaSelection emits ScreenshotSelectingArea',
      build: () => ScreenshotCubit(repository: mockRepository),
      act: (cubit) => cubit.startAreaSelection(testSerial),
      expect: () => [
        isA<ScreenshotSelectingArea>().having(
          (s) => s.deviceSerial,
          'deviceSerial',
          testSerial,
        ),
      ],
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'cancelAreaSelection emits ScreenshotInitial when selecting area',
      build: () => ScreenshotCubit(repository: mockRepository),
      seed: () => const ScreenshotSelectingArea(testSerial),
      act: (cubit) => cubit.cancelAreaSelection(),
      expect: () => [isA<ScreenshotInitial>()],
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'captureScreenshot forwards cropRectNormalized to repository',
      build: () {
        when(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            customSaveDirectory: any(named: 'customSaveDirectory'),
            cropRectNormalized: any(named: 'cropRectNormalized'),
          ),
        ).thenAnswer((_) async => testScreenshot);
        return ScreenshotCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.captureScreenshot(
        testSerial,
        cropRectNormalized: const Rect.fromLTWH(0.1, 0.2, 0.5, 0.4),
      ),
      expect: () => [isA<ScreenshotCapturing>(), isA<ScreenshotSuccess>()],
      verify: (_) {
        verify(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            cropRectNormalized: const Rect.fromLTWH(0.1, 0.2, 0.5, 0.4),
          ),
        ).called(1);
      },
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'reset emits ScreenshotInitial',
      build: () => ScreenshotCubit(repository: mockRepository),
      seed: () => ScreenshotSuccess(testScreenshot),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<ScreenshotInitial>()],
    );
  });
}
