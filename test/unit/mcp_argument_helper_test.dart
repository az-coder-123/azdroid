import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpArgumentHelperExtension', () {
    test('getString returns value by primary key or alias', () {
      final map = <String, dynamic>{'foo': 'bar', 'renamed': 'value'};

      expect(map.getString('foo'), equals('bar'));
      expect(map.getString('missing', aliases: ['renamed']), equals('value'));
      expect(map.getString('missing'), isNull);
    });

    test('getRequiredString returns value or throws McpArgumentException', () {
      final map = <String, dynamic>{'key': 'hello'};

      expect(map.getRequiredString('key'), equals('hello'));
      expect(
        () => map.getRequiredString('missing', aliases: ['unknown']),
        throwsA(isA<McpArgumentException>()),
      );
    });

    test('supports universal key normalization across camelCase, snake_case, and casing', () {
      final map = <String, dynamic>{
        'local_path': '/sdcard/file.txt',
        'DeviceSerial': '192.168.1.100:5555',
        'PACKAGE_NAME': 'com.android.settings',
        'clear-all': true,
        'pollIntervalMs': 250,
      };

      expect(map.getString('localPath'), equals('/sdcard/file.txt'));
      expect(map.getString('device_serial'), equals('192.168.1.100:5555'));
      expect(map.getString('packageName'), equals('com.android.settings'));
      expect(map.getBool('clearAll'), isTrue);
      expect(map.getInt('poll_interval_ms'), equals(250));
    });

    test('getBool correctly parses boolean, string, and integer flags', () {
      final map = <String, dynamic>{
        'b_true': true,
        'b_false': false,
        's_true': 'TRUE',
        's_1': '1',
        's_yes': 'yes',
        's_on': 'on',
        's_enable': 'enable',
        's_false': 'false',
        's_0': '0',
        's_no': 'no',
        'i_1': 1,
        'i_0': 0,
        'alias_flag': 'yes',
      };

      expect(map.getBool('b_true'), isTrue);
      expect(map.getBool('b_false'), isFalse);
      expect(map.getBool('s_true'), isTrue);
      expect(map.getBool('s_1'), isTrue);
      expect(map.getBool('s_yes'), isTrue);
      expect(map.getBool('s_on'), isTrue);
      expect(map.getBool('s_enable'), isTrue);
      expect(map.getBool('s_false'), isFalse);
      expect(map.getBool('s_0'), isFalse);
      expect(map.getBool('s_no'), isFalse);
      expect(map.getBool('i_1'), isTrue);
      expect(map.getBool('i_0'), isFalse);

      // Default value when null/missing
      expect(map.getBool('missing', defaultValue: true), isTrue);
      expect(map.getBool('missing', defaultValue: false), isFalse);

      // Alias lookup
      expect(map.getBool('missing', aliases: ['alias_flag']), isTrue);
    });

    test(
      'getDouble and getRequiredDouble parse numbers and string numbers',
      () {
        final map = <String, dynamic>{
          'd_val': 12.34,
          'i_val': 56,
          's_val': '78.9',
          'alias_val': '99.5',
        };

        expect(map.getDouble('d_val'), closeTo(12.34, 0.001));
        expect(map.getDouble('i_val'), closeTo(56.0, 0.001));
        expect(map.getDouble('s_val'), closeTo(78.9, 0.001));
        expect(
          map.getRequiredDouble('missing', aliases: ['alias_val']),
          closeTo(99.5, 0.001),
        );

        expect(map.getOptionalDouble('missing'), isNull);
        expect(
          map.getDouble('missing', defaultValue: 15.5),
          closeTo(15.5, 0.001),
        );
        expect(
          () => map.getRequiredDouble('missing'),
          throwsA(isA<McpArgumentException>()),
        );
      },
    );

    test('getInt and getRequiredInt parse integers, doubles, and strings', () {
      final map = <String, dynamic>{
        'i_val': 100,
        'd_val': 200.7,
        's_val': '300',
        'alias_val': '400',
      };

      expect(map.getInt('i_val'), equals(100));
      expect(map.getInt('d_val'), equals(200));
      expect(map.getInt('s_val'), equals(300));
      expect(
        map.getRequiredInt('missing', aliases: ['alias_val']),
        equals(400),
      );

      expect(map.getOptionalInt('missing'), isNull);
      expect(map.getInt('missing', defaultValue: 50), equals(50));
      expect(
        () => map.getRequiredInt('missing'),
        throwsA(isA<McpArgumentException>()),
      );
    });
    // Screen points: test/unit/mcp_point_test.dart.
  });
}
