import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/data/models/logcat_threadtime_parser.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';

void main() {
  const parser = LogcatThreadtimeParser();

  group('LogcatThreadtimeParser', () {
    test('parses standard threadtime line with Debug level', () {
      const line =
          '10-14 10:48:15.836  1299  1421 D BatteryService: BatteryUEventObserver real_type: Unknown';

      final entry = parser.parseLine(line, 1);

      expect(entry.id, 1);
      expect(entry.pid, 1299);
      expect(entry.tid, 1421);
      expect(entry.level, LogLevel.debug);
      expect(entry.tag, 'BatteryService');
      expect(entry.message, 'BatteryUEventObserver real_type: Unknown');
      expect(entry.rawLine, line);
    });

    test('parses threadtime lines with all severity levels', () {
      final samples = {
        '10-14 10:48:15.100  100  101 V TagV: verbose msg': LogLevel.verbose,
        '10-14 10:48:15.200  200  201 D TagD: debug msg': LogLevel.debug,
        '10-14 10:48:15.300  300  301 I TagI: info msg': LogLevel.info,
        '10-14 10:48:15.400  400  401 W TagW: warn msg': LogLevel.warn,
        '10-14 10:48:15.500  500  501 E TagE: error msg': LogLevel.error,
        '10-14 10:48:15.600  600  601 F TagF: fatal msg': LogLevel.fatal,
      };

      var id = 1;
      samples.forEach((line, expectedLevel) {
        final entry = parser.parseLine(line, id++);
        expect(entry.level, expectedLevel);
      });
    });

    test('parses system notice marker', () {
      const line = '--------- beginning of system';
      final entry = parser.parseLine(line, 42);

      expect(entry.id, 42);
      expect(entry.level, LogLevel.info);
      expect(entry.tag, 'System');
      expect(entry.message, line);
    });

    test('parses multiline stack trace without standard threadtime header', () {
      const line =
          '    at com.example.MainActivity.onCreate(MainActivity.java:42)';
      final entry = parser.parseLine(line, 99);

      expect(entry.id, 99);
      expect(entry.level, LogLevel.unknown);
      expect(entry.tag, '');
      expect(entry.message, line);
    });

    test('parseLines parses sequential batch with monotonic IDs', () {
      final lines = [
        '10-14 10:48:15.100  100  101 I TagA: message 1',
        '10-14 10:48:15.200  100  101 W TagB: message 2',
      ];
      final entries = parser.parseLines(lines, 10);

      expect(entries.length, 2);
      expect(entries[0].id, 10);
      expect(entries[0].tag, 'TagA');
      expect(entries[1].id, 11);
      expect(entries[1].tag, 'TagB');
    });

    test('parseBatchAsync handles small list synchronously inline', () async {
      final lines = ['10-14 10:48:15.100  100  101 I TagA: inline msg'];
      final entries = await parser.parseBatchAsync(
        lines,
        5,
        isolateThreshold: 50,
      );

      expect(entries.length, 1);
      expect(entries[0].id, 5);
      expect(entries[0].message, 'inline msg');
    });

    test(
      'parseBatchAsync offloads large list to isolate when exceeding threshold',
      () async {
        final lines = List.generate(
          60,
          (i) => '10-14 10:48:15.100  100  101 I TagIsolate: log item $i',
        );
        final entries = await parser.parseBatchAsync(
          lines,
          1,
          isolateThreshold: 50,
        );

        expect(entries.length, 60);
        expect(entries.first.id, 1);
        expect(entries.first.tag, 'TagIsolate');
        expect(entries.last.id, 60);
        expect(entries.last.message, 'log item 59');
      },
    );
  });
}
