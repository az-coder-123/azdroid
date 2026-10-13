import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screen_recording_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';

class MockScreenRecordingRepository extends Mock
    implements ScreenRecordingRepository {}

void main() {
  late MockScreenRecordingRepository mockRepository;
  const testSerial = '192.168.1.100:5555';
  const testRemotePath = '/sdcard/wifidesk_rec_12345.mp4';

  final testRecording = ScreenRecordingEntity(
    filePath: '/Users/mac/Downloads/WifiDesk_Recording_20261013_192000.mp4',
    fileName: 'WifiDesk_Recording_20261013_192000.mp4',
    fileSizeBytes: 1540000,
    duration: const Duration(seconds: 15),
    recordedAt: DateTime(2026, 10, 13, 19, 20),
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockRepository = MockScreenRecordingRepository();
    when(
      () => mockRepository.cancelRecording(
        deviceSerial: any(named: 'deviceSerial'),
        remoteTempPath: any(named: 'remoteTempPath'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ScreenRecordingCubit', () {
    test('initial state is ScreenRecordingInitial', () {
      final cubit = ScreenRecordingCubit(repository: mockRepository);
      expect(cubit.state, isA<ScreenRecordingInitial>());
      cubit.close();
    });

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'startRecording emits ScreenRecordingActive on success',
      build: () {
        when(
          () => mockRepository.startRecording(
            deviceSerial: testSerial,
            bitrateBps: any(named: 'bitrateBps'),
            timeLimitSeconds: any(named: 'timeLimitSeconds'),
          ),
        ).thenAnswer((_) async => testRemotePath);
        return ScreenRecordingCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startRecording(testSerial),
      expect: () => [
        isA<ScreenRecordingActive>().having(
          (s) => s.remoteTempPath,
          'remoteTempPath',
          testRemotePath,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.startRecording(deviceSerial: testSerial))
            .called(1);
      },
    );

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'startRecording emits ScreenRecordingFailure on exception',
      build: () {
        when(
          () => mockRepository.startRecording(
            deviceSerial: testSerial,
            bitrateBps: any(named: 'bitrateBps'),
            timeLimitSeconds: any(named: 'timeLimitSeconds'),
          ),
        ).thenThrow(Exception('screenrecord start failed'));
        return ScreenRecordingCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startRecording(testSerial),
      expect: () => [
        isA<ScreenRecordingFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          contains('screenrecord start failed'),
        ),
      ],
    );

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'stopRecording emits [ScreenRecordingFinalizing, ScreenRecordingSuccess] on success',
      build: () {
        when(
          () => mockRepository.stopRecording(
            deviceSerial: testSerial,
            remoteTempPath: testRemotePath,
            duration: any(named: 'duration'),
            customSaveDirectory: any(named: 'customSaveDirectory'),
          ),
        ).thenAnswer((_) async => testRecording);
        return ScreenRecordingCubit(repository: mockRepository);
      },
      seed: () => ScreenRecordingActive(
        deviceSerial: testSerial,
        remoteTempPath: testRemotePath,
        startedAt: DateTime(2026, 10, 13, 19, 0),
      ),
      act: (cubit) => cubit.stopRecording(),
      expect: () => [
        isA<ScreenRecordingFinalizing>(),
        isA<ScreenRecordingSuccess>().having(
          (s) => s.recording.fileName,
          'fileName',
          'WifiDesk_Recording_20261013_192000.mp4',
        ),
      ],
    );

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'stopRecording emits [ScreenRecordingFinalizing, ScreenRecordingFailure] when repository returns null',
      build: () {
        when(
          () => mockRepository.stopRecording(
            deviceSerial: testSerial,
            remoteTempPath: testRemotePath,
            duration: any(named: 'duration'),
            customSaveDirectory: any(named: 'customSaveDirectory'),
          ),
        ).thenAnswer((_) async => null);
        return ScreenRecordingCubit(repository: mockRepository);
      },
      seed: () => ScreenRecordingActive(
        deviceSerial: testSerial,
        remoteTempPath: testRemotePath,
        startedAt: DateTime(2026, 10, 13, 19, 0),
      ),
      act: (cubit) => cubit.stopRecording(),
      expect: () => [
        isA<ScreenRecordingFinalizing>(),
        isA<ScreenRecordingFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'No recording video data received',
        ),
      ],
    );

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'cancelRecording emits ScreenRecordingInitial and calls repository.cancelRecording',
      build: () {
        when(
          () => mockRepository.cancelRecording(
            deviceSerial: testSerial,
            remoteTempPath: testRemotePath,
          ),
        ).thenAnswer((_) async {});
        return ScreenRecordingCubit(repository: mockRepository);
      },
      seed: () => ScreenRecordingActive(
        deviceSerial: testSerial,
        remoteTempPath: testRemotePath,
        startedAt: DateTime(2026, 10, 13, 19, 0),
      ),
      act: (cubit) => cubit.cancelRecording(),
      expect: () => [isA<ScreenRecordingInitial>()],
      verify: (_) {
        verify(
          () => mockRepository.cancelRecording(
            deviceSerial: testSerial,
            remoteTempPath: testRemotePath,
          ),
        ).called(1);
      },
    );

    blocTest<ScreenRecordingCubit, ScreenRecordingState>(
      'reset emits ScreenRecordingInitial',
      build: () => ScreenRecordingCubit(repository: mockRepository),
      seed: () => ScreenRecordingSuccess(testRecording),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<ScreenRecordingInitial>()],
    );
  });
}
