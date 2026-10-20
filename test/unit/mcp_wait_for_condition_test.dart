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

  group('android_wait_for_condition Tests', () {
    test('succeeds when element_present condition is met', () async {
      when(
        () => mockAdb.waitForCondition(
          '192.168.1.100:5555',
          condition: 'element_present',
          target: null,
          text: 'Login',
          resourceId: null,
          contentDesc: null,
          timeoutMs: 5000,
          pollIntervalMs: 300,
        ),
      ).thenAnswer(
        (_) async => {
          'conditionMet': true,
          'condition': 'element_present',
          'elapsedMs': 240,
          'element': {'text': 'Login', 'bounds': [100, 200, 300, 400]},
        },
      );

      final res = await executor.execute('android_wait_for_condition', {
        'deviceSerial': '192.168.1.100:5555',
        'condition': 'element_present',
        'text': 'Login',
        'timeoutMs': 5000,
      });

      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('Condition "element_present" met (240ms)'));
      expect(res.content.first.text, contains('Login'));
    });

    test('succeeds when activity_resumed condition matches foreground app', () async {
      when(
        () => mockAdb.waitForCondition(
          '192.168.1.100:5555',
          condition: 'activity_resumed',
          target: 'MainActivity',
          text: null,
          resourceId: null,
          contentDesc: null,
          timeoutMs: 8000,
          pollIntervalMs: 300,
        ),
      ).thenAnswer(
        (_) async => {
          'conditionMet': true,
          'condition': 'activity_resumed',
          'elapsedMs': 600,
          'package': 'com.example.app',
          'activity': 'com.example.app.MainActivity',
        },
      );

      final res = await executor.execute('android_wait_for_condition', {
        'deviceSerial': '192.168.1.100:5555',
        'condition': 'activity_resumed',
        'target': 'MainActivity',
        'timeoutMs': 8000,
      });

      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('Condition "activity_resumed" met (600ms)'));
      expect(res.content.first.text, contains('MainActivity'));
    });

    test('succeeds when logcat_match condition finds pattern', () async {
      when(
        () => mockAdb.waitForCondition(
          '192.168.1.100:5555',
          condition: 'logcat_match',
          target: 'HTTP 200 OK',
          text: null,
          resourceId: null,
          contentDesc: null,
          timeoutMs: 10000,
          pollIntervalMs: 300,
        ),
      ).thenAnswer(
        (_) async => {
          'conditionMet': true,
          'condition': 'logcat_match',
          'elapsedMs': 850,
          'matched': 'HTTP 200 OK',
        },
      );

      final res = await executor.execute('android_wait_for_condition', {
        'deviceSerial': '192.168.1.100:5555',
        'condition': 'logcat_match',
        'target': 'HTTP 200 OK',
      });

      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('Condition "logcat_match" met (850ms)'));
      expect(res.content.first.text, contains('HTTP 200 OK'));
    });

    test('returns error when condition times out', () async {
      when(
        () => mockAdb.waitForCondition(
          '192.168.1.100:5555',
          condition: 'element_gone',
          target: null,
          text: 'LoadingSpinner',
          resourceId: null,
          contentDesc: null,
          timeoutMs: 3000,
          pollIntervalMs: 300,
        ),
      ).thenAnswer(
        (_) async => {
          'conditionMet': false,
          'condition': 'element_gone',
          'elapsedMs': 3010,
          'error': 'Timed out after 3000ms waiting for element_gone',
        },
      );

      final res = await executor.execute('android_wait_for_condition', {
        'deviceSerial': '192.168.1.100:5555',
        'condition': 'element_gone',
        'text': 'LoadingSpinner',
        'timeoutMs': 3000,
      });

      expect(res.isError, isTrue);
      expect(res.content.first.text, contains('Timed out after 3000ms'));
    });
  });
}
