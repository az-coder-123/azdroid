import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_host_file_launcher.dart';

class MockScreenshotRepository extends Mock implements ScreenshotRepository {}

class MockHostFileLauncher extends Mock implements HostFileLauncher {}

void main() {
  late MockScreenshotRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  final testScreenshot = ScreenshotEntity(
    filePath: '/Users/mac/Downloads/Azdroid_Screenshot_20261013_183000.png',
    fileName: 'Azdroid_Screenshot_20261013_183000.png',
    fileSizeBytes: 245000,
    capturedAt: DateTime(2026, 10, 13, 18, 30),
    copiedToClipboard: true,
  );

  setUpAll(() {
    registerFallbackValue(ScreenshotDestination.both);
  });

  setUp(() {
    mockRepository = MockScreenshotRepository();
  });

  group('ScreenshotCubit', () {
    test('initial state is ScreenshotInitial', () {
      final cubit = ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: FakeHostFileLauncher(),
      );
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
        return ScreenshotCubit(
          repository: mockRepository,
          fileLauncher: FakeHostFileLauncher(),
        );
      },
      act: (cubit) => cubit.captureScreenshot(testSerial),
      expect: () => [
        isA<ScreenshotCapturing>(),
        isA<ScreenshotSuccess>().having(
          (s) => s.screenshot.fileName,
          'fileName',
          'Azdroid_Screenshot_20261013_183000.png',
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
        return ScreenshotCubit(
          repository: mockRepository,
          fileLauncher: FakeHostFileLauncher(),
        );
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
        return ScreenshotCubit(
          repository: mockRepository,
          fileLauncher: FakeHostFileLauncher(),
        );
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
      build: () => ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: FakeHostFileLauncher(),
      ),
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
      build: () => ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: FakeHostFileLauncher(),
      ),
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
        return ScreenshotCubit(
          repository: mockRepository,
          fileLauncher: FakeHostFileLauncher(),
        );
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
      'captureScreenshot forwards destination to repository',
      build: () {
        when(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            customSaveDirectory: any(named: 'customSaveDirectory'),
            cropRectNormalized: any(named: 'cropRectNormalized'),
            destination: any(named: 'destination'),
          ),
        ).thenAnswer((_) async => testScreenshot);
        return ScreenshotCubit(
          repository: mockRepository,
          fileLauncher: FakeHostFileLauncher(),
        );
      },
      act: (cubit) => cubit.captureScreenshot(
        testSerial,
        destination: ScreenshotDestination.clipboard,
      ),
      expect: () => [isA<ScreenshotCapturing>(), isA<ScreenshotSuccess>()],
      verify: (_) {
        verify(
          () => mockRepository.captureScreenshot(
            deviceSerial: testSerial,
            destination: ScreenshotDestination.clipboard,
          ),
        ).called(1);
      },
    );

    blocTest<ScreenshotCubit, ScreenshotState>(
      'reset emits ScreenshotInitial',
      build: () => ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: FakeHostFileLauncher(),
      ),
      seed: () => ScreenshotSuccess(testScreenshot),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<ScreenshotInitial>()],
    );
  });

  group('ScreenshotCubit file actions', () {
    late MockHostFileLauncher launcher;
    const filePath = '/Users/mac/Downloads/capture.file';

    setUp(() {
      launcher = MockHostFileLauncher();
      when(() => launcher.open(any())).thenAnswer((_) async => true);
      when(() => launcher.reveal(any())).thenAnswer((_) async => true);
    });

    test('revealFile delegates to HostFileLauncher', () async {
      final cubit = ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: launcher,
      );
      await cubit.revealFile(filePath);
      verify(() => launcher.reveal(filePath)).called(1);
      await cubit.close();
    });

    test('openFile delegates to HostFileLauncher', () async {
      final cubit = ScreenshotCubit(
        repository: mockRepository,
        fileLauncher: launcher,
      );
      await cubit.openFile(filePath);
      verify(() => launcher.open(filePath)).called(1);
      await cubit.close();
    });
  });
}
