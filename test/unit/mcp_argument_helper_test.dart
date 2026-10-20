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

    test(
      'getPoint resolves pixel, explicit ratio, and normalized coordinates',
      () {
        const displayW = 1080;
        const displayH = 2400;

        // 1. Raw pixel coordinates
        final pixels = <String, dynamic>{'x': 500, 'y': 1000};
        final p1 = pixels.getPoint(
          displayWidth: displayW,
          displayHeight: displayH,
        );
        expect(p1.$1, closeTo(500, 0.001));
        expect(p1.$2, closeTo(1000, 0.001));

        // 2. Explicit ratios: xRatio / yRatio
        final ratios = <String, dynamic>{'xRatio': 0.5, 'yRatio': 0.25};
        final p2 = ratios.getPoint(
          displayWidth: displayW,
          displayHeight: displayH,
        );
        expect(p2.$1, closeTo(540, 0.001));
        expect(p2.$2, closeTo(600, 0.001));

        // 3. Snake_case ratios: x_ratio / y_ratio
        final snakeRatios = <String, dynamic>{'x_ratio': 0.1, 'y_ratio': 0.5};
        final p3 = snakeRatios.getPoint(
          displayWidth: displayW,
          displayHeight: displayH,
        );
        expect(p3.$1, closeTo(108, 0.001));
        expect(p3.$2, closeTo(1200, 0.001));

        // 4. Custom keys with aliases: startX / startY
        final custom = <String, dynamic>{
          'startXRatio': 0.8,
          'startYRatio': 0.1,
        };
        final p4 = custom.getPoint(
          displayWidth: displayW,
          displayHeight: displayH,
          xKey: 'startX',
          yKey: 'startY',
        );
        expect(p4.$1, closeTo(864, 0.001));
        expect(p4.$2, closeTo(240, 0.001));
      },
    );

    test('getPointPair resolves ratio arguments or raw values without display size', () {
      final ratioMap = <String, dynamic>{'xRatio': 0.4, 'yRatio': 0.6};
      final (rx, ry) = ratioMap.getPointPair();
      expect(rx, closeTo(0.4, 0.001));
      expect(ry, closeTo(0.6, 0.001));

      final percentMap = <String, dynamic>{
        'x_percent': 0.75,
        'y_percent': 0.25,
      };
      final (px, py) = percentMap.getPointPair();
      expect(px, closeTo(0.75, 0.001));
      expect(py, closeTo(0.25, 0.001));

      final rawMap = <String, dynamic>{'x': 540.0, 'y': 960.0};
      final (cx, cy) = rawMap.getPointPair();
      expect(cx, closeTo(540.0, 0.001));
      expect(cy, closeTo(960.0, 0.001));
    });
  });
}
