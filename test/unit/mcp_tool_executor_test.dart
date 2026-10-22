import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpAdbClient extends Mock implements McpAdbClient {}

void main() {
  late MockMcpAdbClient mockAdb;
  late McpToolExecutor executor;

  setUp(() {
    mockAdb = MockMcpAdbClient();
    executor = McpToolExecutor(adbClient: mockAdb);
  });

  group('McpToolExecutor Basic Tools Tests', () {
    test('android_list_devices lists devices from raw ADB output', () async {
      when(() => mockAdb.listDevicesRaw()).thenAnswer(
        (_) async =>
            '192.168.1.100:5555 device product:raven model:Pixel_6_Pro',
      );

      final result = await executor.execute('android_list_devices', {});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('192.168.1.100:5555'));
      expect(result.content.first.text, contains('Pixel_6_Pro'));
    });

    test('android_tap executes tap via McpAdbClient', () async {
      when(() => mockAdb.tap('192.168.1.100:5555', 0.5, 0.75))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_tap', {
        'deviceSerial': '192.168.1.100:5555',
        'x': 0.5,
        'y': 0.75,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Tapped at coordinates (0.5, 0.75)'),
      );
    });

    test(
      'android_tap accepts normalized xRatio and yRatio arguments',
      () async {
        when(() => mockAdb.tap('192.168.1.100:5555', 0.25, 0.65))
            .thenAnswer((_) async => true);

        final result = await executor.execute('android_tap', {
          'deviceSerial': '192.168.1.100:5555',
          'x_ratio': 0.25,
          'y_ratio': 0.65,
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('Tapped at coordinates (0.25, 0.65)'),
        );
      },
    );

    test(
      'android_tap accepts physical pixel xPixel and yPixel arguments',
      () async {
        when(() => mockAdb.tap('192.168.1.100:5555', 540.0, 1170.0))
            .thenAnswer((_) async => true);

        final result = await executor.execute('android_tap', {
          'deviceSerial': '192.168.1.100:5555',
          'xPixel': 540,
          'yPixel': 1170,
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('Tapped at coordinates (540.0, 1170.0)'),
        );
      },
    );

    test(
      'android_tap with verifyChange: true reports verified state change',
      () async {
        when(
          () => mockAdb.tapAndVerify(
            '192.168.1.100:5555',
            0.5,
            0.75,
            delayMs: any(named: 'delayMs'),
          ),
        ).thenAnswer((_) async => (true, true));

        final result = await executor.execute('android_tap', {
          'deviceSerial': '192.168.1.100:5555',
          'x': 0.5,
          'y': 0.75,
          'verifyChange': true,
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('State change verified'));
      },
    );

    test(
      'android_tap with verifyChange: true warns when UI remained unchanged',
      () async {
        when(
          () => mockAdb.tapAndVerify(
            '192.168.1.100:5555',
            0.1,
            0.1,
            delayMs: any(named: 'delayMs'),
          ),
        ).thenAnswer((_) async => (true, false));

        final result = await executor.execute('android_tap', {
          'deviceSerial': '192.168.1.100:5555',
          'x': 0.1,
          'y': 0.1,
          'verifyChange': true,
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('Warning: Tap produced no detectable UI change'),
        );
      },
    );

    test(
      'android_tap with verifyChange: true returns error on tap failure',
      () async {
        when(
          () => mockAdb.tapAndVerify(
            '192.168.1.100:5555',
            0.1,
            0.1,
            delayMs: any(named: 'delayMs'),
          ),
        ).thenAnswer((_) async => (false, false));

        final result = await executor.execute('android_tap', {
          'deviceSerial': '192.168.1.100:5555',
          'x': 0.1,
          'y': 0.1,
          'verifyChange': true,
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Failed to tap'));
      },
    );

    test('android_double_tap executes double tap via McpAdbClient', () async {
      when(
        () =>
            mockAdb.doubleTap('192.168.1.100:5555', 0.5, 0.75, intervalMs: 120),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_double_tap', {
        'deviceSerial': '192.168.1.100:5555',
        'x': 0.5,
        'y': 0.75,
        'intervalMs': 120,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains(
          'Double-tapped at coordinates (0.5, 0.75) with 120ms interval',
        ),
      );
    });

    test('android_set_text injects exact text via McpAdbClient', () async {
      when(
        () => mockAdb.setText(
          '192.168.1.100:5555',
          'Hello OpenPlayer3',
          elementId: 5,
          clearFirst: true,
        ),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_set_text', {
        'deviceSerial': '192.168.1.100:5555',
        'text': 'Hello OpenPlayer3',
        'elementId': 5,
        'clearFirst': true,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Set text "Hello OpenPlayer3" on 192.168.1.100:5555'),
      );
    });

    test('android_clear_text resets text via McpAdbClient', () async {
      when(() => mockAdb.clearText('192.168.1.100:5555', elementId: 5))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_clear_text', {
        'deviceSerial': '192.168.1.100:5555',
        'elementId': 5,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Cleared text on 192.168.1.100:5555'),
      );
    });

    test('android_swipe executes swipe via McpAdbClient', () async {
      when(() => mockAdb.swipe('192.168.1.100:5555', 0.5, 0.8, 0.5, 0.2, 300))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_swipe', {
        'deviceSerial': '192.168.1.100:5555',
        'startX': 0.5,
        'startY': 0.8,
        'endX': 0.5,
        'endY': 0.2,
        'durationMs': 300,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Swiped from (0.5, 0.8) to (0.5, 0.2)'),
      );
    });

    test(
      'android_swipe accepts ratio arguments (startXRatio, endXRatio, etc.)',
      () async {
        when(() => mockAdb.swipe('192.168.1.100:5555', 0.2, 0.3, 0.8, 0.9, 450))
            .thenAnswer((_) async => true);

        final result = await executor.execute('android_swipe', {
          'deviceSerial': '192.168.1.100:5555',
          'startXRatio': 0.2,
          'startYRatio': 0.3,
          'endXRatio': 0.8,
          'endYRatio': 0.9,
          'durationMs': 450,
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('Swiped from (0.2, 0.3) to (0.8, 0.9)'),
        );
      },
    );

    test('android_swipe accepts physical pixel arguments (startXPixel, endXPixel, etc.)', () async {
      when(
        () => mockAdb.swipe(
          '192.168.1.100:5555',
          100.0,
          200.0,
          100.0,
          1200.0,
          500,
        ),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_swipe', {
        'deviceSerial': '192.168.1.100:5555',
        'startXPixel': 100,
        'startYPixel': 200,
        'endXPixel': 100,
        'endYPixel': 1200,
        'durationMs': 500,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Swiped from (100.0, 200.0) to (100.0, 1200.0)'),
      );
    });

    test('android_type_text injects string via McpAdbClient', () async {
      when(() => mockAdb.typeText('192.168.1.100:5555', 'Hello AI'))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_type_text', {
        'deviceSerial': '192.168.1.100:5555',
        'text': 'Hello AI',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Injected text "Hello AI"'));
    });

    test('android_press_key translates key name to keycode', () async {
      when(() => mockAdb.pressKey('192.168.1.100:5555', 4))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_press_key', {
        'deviceSerial': '192.168.1.100:5555',
        'key': 'BACK',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Pressed key BACK (4)'));
    });

    test('android_drag executes drag via McpAdbClient', () async {
      when(
        () => mockAdb.drag(
          '192.168.1.100:5555',
          0.1,
          0.5,
          0.9,
          0.5,
          durationMs: 1000,
        ),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_drag', {
        'deviceSerial': '192.168.1.100:5555',
        'startX': 0.1,
        'startY': 0.5,
        'endX': 0.9,
        'endY': 0.5,
        'durationMs': 1000,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Dragged from (0.1, 0.5) to (0.9, 0.5) with duration 1000ms'),
      );
    });

    test('android_check_crash queries crash logs via McpAdbClient', () async {
      when(
        () => mockAdb.checkCrash(
          '192.168.1.100:5555',
          package: 'com.example.app',
          limit: 30,
        ),
      ).thenAnswer(
        (_) async => 'FATAL EXCEPTION in main: java.lang.NullPointerException',
      );

      final result = await executor.execute('android_check_crash', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.example.app',
        'limit': 30,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Crash diagnostics for com.example.app (up to 30 entries)'),
      );
      expect(result.content.first.text, contains('FATAL EXCEPTION in main'));
    });

    test(
      'android_scan_media_file triggers media indexer via McpAdbClient',
      () async {
        when(
          () => mockAdb.scanMediaFile(
            '192.168.1.100:5555',
            '/sdcard/Music/test.mp3',
          ),
        ).thenAnswer((_) async => true);

        final result = await executor.execute('android_scan_media_file', {
          'deviceSerial': '192.168.1.100:5555',
          'filePath': '/sdcard/Music/test.mp3',
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains(
            'Triggered MediaStore scan for file: /sdcard/Music/test.mp3 on 192.168.1.100:5555',
          ),
        );
      },
    );

    test('returns error when tool is unknown', () async {
      when(() => mockAdb.getConnectedSerials())
          .thenAnswer((_) async => ['192.168.1.100:5555']);

      final result = await executor.execute('android_unknown_tool', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        contains('Unknown tool: android_unknown_tool'),
      );
    });
  });
}
