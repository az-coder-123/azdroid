import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';
import 'package:wifi_desk/features/logging/domain/repositories/device_log_repository.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_state.dart';

class MockDeviceLogRepository extends Mock implements DeviceLogRepository {}

void main() {
  late MockDeviceLogRepository mockRepository;
  const testSerial = '192.168.43.148:5555';

  final sampleEntry = DeviceLogEntry(
    id: 1,
    timestamp: DateTime.now(),
    pid: 1299,
    tid: 1421,
    level: LogLevel.debug,
    tag: 'BatteryService',
    message: 'Battery level 95%',
    rawLine: 'raw sample line',
  );

  setUp(() {
    mockRepository = MockDeviceLogRepository();
    when(() => mockRepository.recordingStatus)
        .thenReturn(LogFileRecordingStatus.idle());
    when(() => mockRepository.stopStream()).thenReturn(null);
    when(() => mockRepository.dispose()).thenReturn(null);
  });

  group('DeviceLogCubit', () {
    test('initial state is DeviceLogInitial', () {
      final cubit = DeviceLogCubit(repository: mockRepository);
      expect(cubit.state, isA<DeviceLogInitial>());
      cubit.close();
    });

    blocTest<DeviceLogCubit, DeviceLogState>(
      'startLogging emits DeviceLogStreaming and receives incoming batches',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => Stream.value([sampleEntry]));
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startLogging(testSerial),
      expect: () => [
        isA<DeviceLogStreaming>().having(
          (s) => s.allEntries.length,
          'allEntries.length',
          0,
        ),
        isA<DeviceLogStreaming>()
            .having((s) => s.allEntries.length, 'allEntries.length', 1)
            .having(
              (s) => s.filteredEntries.length,
              'filteredEntries.length',
              1,
            ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'togglePause toggles isPaused state',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.togglePause();
      },
      expect: () => [
        isA<DeviceLogStreaming>().having((s) => s.isPaused, 'isPaused', false),
        isA<DeviceLogStreaming>().having((s) => s.isPaused, 'isPaused', true),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleAutoScroll inverts autoScroll flag',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.toggleAutoScroll();
      },
      expect: () => [
        isA<DeviceLogStreaming>().having(
          (s) => s.autoScroll,
          'autoScroll',
          true,
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.autoScroll,
          'autoScroll',
          false,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'clearConsole removes in-memory entries',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => Stream.value([sampleEntry]));
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) async {
        cubit.startLogging(testSerial);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        cubit.clearConsole();
      },
      expect: () => [
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 0),
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 1),
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 0),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'clearDeviceBuffer calls repository and resets in-memory entries',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => Stream.value([sampleEntry]));
        when(() => mockRepository.clearDeviceBuffer(testSerial))
            .thenAnswer((_) async {});
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) async {
        cubit.startLogging(testSerial);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cubit.clearDeviceBuffer();
      },
      expect: () => [
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 0),
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 1),
        isA<DeviceLogStreaming>().having((s) => s.allEntries.length, 'len', 0),
        isA<DeviceLogStreaming>().having(
          (s) => s.feedbackMessage,
          'msg',
          contains('cleared'),
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleFileRecording starts recording when currently idle',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        when(
          () => mockRepository.startRecordingToFile(
            deviceSerial: testSerial,
            customDirectory: any(named: 'customDirectory'),
            customFilePath: any(named: 'customFilePath'),
          ),
        ).thenAnswer((_) async => '/tmp/test.log');
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) async {
        cubit.startLogging(testSerial);
        await cubit.toggleFileRecording();
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.feedbackMessage,
          'msg',
          contains('/tmp/test.log'),
        ),
      ],
    );

    test('DeviceLogStreaming.tagCounts computes unique tags sorted by frequency', () {
      final now = DateTime.now();
      final streaming = DeviceLogStreaming(
        deviceSerial: testSerial,
        allEntries: [
          DeviceLogEntry(
            id: 1,
            timestamp: now,
            pid: 1,
            tid: 1,
            level: LogLevel.info,
            tag: 'Finsky',
            message: 'msg 1',
            rawLine: '',
          ),
          DeviceLogEntry(
            id: 2,
            timestamp: now,
            pid: 1,
            tid: 1,
            level: LogLevel.info,
            tag: 'Finsky',
            message: 'msg 2',
            rawLine: '',
          ),
          DeviceLogEntry(
            id: 3,
            timestamp: now,
            pid: 1,
            tid: 1,
            level: LogLevel.info,
            tag: 'ThermalInfo',
            message: 'msg 3',
            rawLine: '',
          ),
        ],
        filteredEntries: const [],
        filter: const LogFilterCriteria(),
        recordingStatus: LogFileRecordingStatus.idle(),
      );

      expect(streaming.tagCounts, equals({
        'Finsky': 2,
        'ThermalInfo': 1,
      }));
    });
  });
}
