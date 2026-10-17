import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';

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
