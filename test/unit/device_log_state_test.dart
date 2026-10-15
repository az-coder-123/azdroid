import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';

void main() {
  group('DeviceLogStreaming computed getters', () {
    final now = DateTime.now();

    DeviceLogEntry createEntry({
      required int id,
      required int pid,
      required String tag,
    }) {
      return DeviceLogEntry(
        id: id,
        timestamp: now,
        pid: pid,
        tid: 1,
        level: LogLevel.info,
        tag: tag,
        message: 'log $id',
        rawLine: 'raw $id',
      );
    }

    test('computes tagCounts sorted by descending frequency', () {
      final streaming = DeviceLogStreaming(
        deviceSerial: 'device1',
        allEntries: [
          createEntry(id: 1, pid: 100, tag: 'Finsky'),
          createEntry(id: 2, pid: 200, tag: 'ThermalInfo'),
          createEntry(id: 3, pid: 100, tag: 'Finsky'),
          createEntry(id: 4, pid: 300, tag: 'Finsky'),
        ],
        filteredEntries: const [],
        filter: const LogFilterCriteria(),
        recordingStatus: LogFileRecordingStatus.idle(),
      );

      expect(streaming.tagCounts, equals({'Finsky': 3, 'ThermalInfo': 1}));
    });

    test('computes pidCounts sorted by descending frequency', () {
      final streaming = DeviceLogStreaming(
        deviceSerial: 'device1',
        allEntries: [
          createEntry(id: 1, pid: 100, tag: 'Finsky'),
          createEntry(id: 2, pid: 200, tag: 'ThermalInfo'),
          createEntry(id: 3, pid: 100, tag: 'Finsky'),
          createEntry(id: 4, pid: 100, tag: 'Auth'),
          createEntry(id: 5, pid: 200, tag: 'ThermalInfo'),
          createEntry(id: 6, pid: 300, tag: 'Kernel'),
        ],
        filteredEntries: const [],
        filter: const LogFilterCriteria(),
        recordingStatus: LogFileRecordingStatus.idle(),
      );

      expect(streaming.pidCounts, equals({100: 3, 200: 2, 300: 1}));
    });

    test(
      'computes pidPrimaryTags mapping each PID to its most frequent tag',
      () {
        final streaming = DeviceLogStreaming(
          deviceSerial: 'device1',
          allEntries: [
            createEntry(id: 1, pid: 100, tag: 'Finsky'),
            createEntry(id: 2, pid: 100, tag: 'Finsky'),
            createEntry(id: 3, pid: 100, tag: 'SecondaryService'),
            createEntry(id: 4, pid: 200, tag: 'ThermalInfo'),
          ],
          filteredEntries: const [],
          filter: const LogFilterCriteria(),
          recordingStatus: LogFileRecordingStatus.idle(),
        );

        expect(
          streaming.pidPrimaryTags,
          equals({100: 'Finsky', 200: 'ThermalInfo'}),
        );
      },
    );
  });
}
