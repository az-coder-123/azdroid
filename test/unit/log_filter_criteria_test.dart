import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';

void main() {
  group('LogFilterCriteria', () {
    final now = DateTime.now();

    final entry1 = DeviceLogEntry(
      id: 1,
      timestamp: now,
      pid: 1001,
      tid: 2001,
      level: LogLevel.info,
      tag: 'ActivityManager',
      message: 'Start proc 1001:com.example/u0a123',
      rawLine: 'raw 1',
    );

    final entry2 = DeviceLogEntry(
      id: 2,
      timestamp: now,
      pid: 1002,
      tid: 2002,
      level: LogLevel.error,
      tag: 'AndroidRuntime',
      message: 'FATAL EXCEPTION: main',
      rawLine: 'raw 2',
    );

    test('default criteria matches all entries', () {
      const criteria = LogFilterCriteria();
      expect(criteria.matches(entry1), isTrue);
      expect(criteria.matches(entry2), isTrue);
    });

    test('filters by selected log levels', () {
      const criteria = LogFilterCriteria(
        selectedLevels: {LogLevel.error, LogLevel.fatal},
      );
      expect(criteria.matches(entry1), isFalse);
      expect(criteria.matches(entry2), isTrue);
    });

    test('filters by PID', () {
      const criteria = LogFilterCriteria(pidFilter: 1001);
      expect(criteria.matches(entry1), isTrue);
      expect(criteria.matches(entry2), isFalse);
    });

    test('filters by tag query', () {
      const criteria = LogFilterCriteria(tagFilter: 'Activity');
      expect(criteria.matches(entry1), isTrue);
      expect(criteria.matches(entry2), isFalse);
    });

    test('filters by text query in message', () {
      const criteria = LogFilterCriteria(textQuery: 'FATAL');
      expect(criteria.matches(entry1), isFalse);
      expect(criteria.matches(entry2), isTrue);
    });

    test('supports regular expression matching', () {
      const criteria = LogFilterCriteria(
        textQuery: r'Start proc \d+',
        isRegex: true,
      );
      expect(criteria.matches(entry1), isTrue);
      expect(criteria.matches(entry2), isFalse);
    });

    test('supports case-sensitive matching', () {
      const criteria = LogFilterCriteria(
        textQuery: 'fatal',
        caseSensitive: true,
      );
      // entry2 has 'FATAL', so it shouldn't match with caseSensitive: true
      expect(criteria.matches(entry2), isFalse);
    });

    test('filters by bookmarksOnly when bookmarkedIds provided', () {
      const criteria = LogFilterCriteria(bookmarksOnly: true);
      expect(criteria.matches(entry1, bookmarkedIds: {1}), isTrue);
      expect(criteria.matches(entry2, bookmarkedIds: {1}), isFalse);
    });

    test('filters out excluded tags', () {
      const criteria = LogFilterCriteria(excludeTags: {'AndroidRuntime'});
      expect(criteria.matches(entry1), isTrue);
      expect(criteria.matches(entry2), isFalse);
    });
  });
}
