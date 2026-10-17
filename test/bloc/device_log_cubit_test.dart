import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:desk_droid/features/logging/domain/repositories/device_log_repository.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';

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

    blocTest<DeviceLogCubit, DeviceLogState>(
      'selectEntry selects entry and deselects when clicked again',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.selectEntry(sampleEntry);
        cubit.selectEntry(sampleEntry);
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.selectedEntry,
          'selectedEntry',
          sampleEntry,
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.selectedEntry,
          'selectedEntry',
          isNull,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleBookmark adds and removes id from bookmarkedIds',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.toggleBookmark(1);
        cubit.toggleBookmark(1);
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.bookmarkedIds,
          'bookmarkedIds',
          contains(1),
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.bookmarkedIds,
          'bookmarkedIds',
          isEmpty,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleBookmarksOnly toggles bookmarksOnly filter flag',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.toggleBookmarksOnly();
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.bookmarksOnly,
          'bookmarksOnly',
          isTrue,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleSoftWrap inverts softWrap state flag',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.toggleSoftWrap();
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having((s) => s.softWrap, 'softWrap', isTrue),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'excludeTag adds tag, removeExcludeTag removes it, and clearExcludeTags resets',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.excludeTag('chatty');
        cubit.excludeTag('ViewRootImpl');
        cubit.removeExcludeTag('chatty');
        cubit.clearExcludeTags();
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.excludeTags,
          'excludeTags',
          {'chatty'},
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.excludeTags,
          'excludeTags',
          {'chatty', 'ViewRootImpl'},
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.excludeTags,
          'excludeTags',
          {'ViewRootImpl'},
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.excludeTags,
          'excludeTags',
          isEmpty,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'toggleLevel, updateSearch, toggleRegex, toggleCaseSensitive update criteria',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) {
        cubit.startLogging(testSerial);
        cubit.toggleLevel(LogLevel.error);
        cubit.updateSearch('crash');
        cubit.toggleRegex();
        cubit.toggleCaseSensitive();
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.selectedLevels.contains(LogLevel.error),
          'selectedLevels contains error',
          isTrue,
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.textQuery,
          'textQuery',
          'crash',
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.isRegex,
          'isRegex',
          isTrue,
        ),
        isA<DeviceLogStreaming>().having(
          (s) => s.filter.caseSensitive,
          'caseSensitive',
          isTrue,
        ),
      ],
    );

    blocTest<DeviceLogCubit, DeviceLogState>(
      'exportLogs delegates to repository with active entries',
      build: () {
        when(() => mockRepository.streamLogs(testSerial))
            .thenAnswer((_) => const Stream.empty());
        when(
          () => mockRepository.exportLogsToFile(
            entries: any(named: 'entries'),
            destinationPath: any(named: 'destinationPath'),
          ),
        ).thenAnswer((_) async => '/tmp/exported.log');
        return DeviceLogCubit(repository: mockRepository);
      },
      act: (cubit) async {
        cubit.startLogging(testSerial);
        await cubit.exportLogs(destinationPath: '/tmp/exported.log');
      },
      expect: () => [
        isA<DeviceLogStreaming>(),
        isA<DeviceLogStreaming>().having(
          (s) => s.feedbackMessage,
          'feedbackMessage',
          contains('Exported'),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.exportLogsToFile(
            entries: any(named: 'entries'),
            destinationPath: '/tmp/exported.log',
          ),
        ).called(1);
      },
    );
  });
}
