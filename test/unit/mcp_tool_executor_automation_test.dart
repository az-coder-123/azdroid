import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mcp_points.dart';

class MockMcpAdbClient extends Mock implements McpAdbClient {}

void main() {
  late MockMcpAdbClient mockAdb;
  late McpToolExecutor executor;

  setUp(() {
    mockAdb = MockMcpAdbClient();
    executor = McpToolExecutor(adbClient: mockAdb);
  });

  group('McpToolExecutor Automation & Macro Ops Tests', () {
    test(
      'android_wait_for_element returns matched element when found',
      () async {
        when(
          () => mockAdb.waitForElement(
            '192.168.1.100:5555',
            text: 'Confirm',
            resourceId: null,
            contentDesc: null,
            timeoutMs: 5000,
            pollIntervalMs: 200,
          ),
        ).thenAnswer(
          (_) async => {
            'text': 'Confirm',
            'centerX': 0.5,
            'centerY': 0.8,
            'elapsedMs': 450,
          },
        );

        final res = await executor.execute('android_wait_for_element', {
          'deviceSerial': '192.168.1.100:5555',
          'text': 'Confirm',
          'timeoutMs': 5000,
          'pollIntervalMs': 200,
        });

        expect(res.isError, isFalse);
        expect(res.content.first.text, contains('Element appeared (450ms)'));
      },
    );

    test(
      'android_batch_actions executes list of actions successfully',
      () async {
        when(() => mockAdb.batchActions('192.168.1.100:5555', any()))
            .thenAnswer(
              (_) async => [
                {'step': 0, 'action': 'tap', 'success': true},
                {'step': 1, 'action': 'type', 'success': true},
              ],
            );

        final res = await executor.execute('android_batch_actions', {
          'deviceSerial': '192.168.1.100:5555',
          'actions': [
            {'action': 'tap', 'x': 0.5, 'y': 0.5},
            {'action': 'type', 'text': 'hello'},
          ],
        });

        expect(res.isError, isFalse);
        expect(res.content.first.text, contains('Executed 2 batch actions'));
      },
    );

    test(
      'android_get_notifications returns parsed notification records',
      () async {
        when(
          () => mockAdb.getNotifications('192.168.1.100:5555', filter: 'Bank'),
        ).thenAnswer(
          (_) async => [
            {
              'package': 'com.bank.app',
              'title': 'OTP Code',
              'text': 'Your code is 123456',
            },
          ],
        );

        final res = await executor.execute('android_get_notifications', {
          'deviceSerial': '192.168.1.100:5555',
          'filter': 'Bank',
        });

        expect(res.isError, isFalse);
        expect(
          res.content.first.text,
          contains('OTP Code: Your code is 123456'),
        );
      },
    );

    test(
      'android_dismiss_notification snoozes one key; clear all is refused',
      () async {
        const key = '0|com.example|2|tag|10202';
        when(
          () => mockAdb.snoozeNotification(
            '192.168.1.100:5555',
            key: key,
            hideFor: const Duration(minutes: 60),
          ),
        ).thenAnswer((_) async => true);

        final res = await executor.execute('android_dismiss_notification', {
          'deviceSerial': '192.168.1.100:5555',
          'key': key,
        });
        expect(res.isError, isFalse);
        expect(res.content.first.text, contains('Hid notification $key'));

        // It used to send `service call statusbar 1`, which only opens the
        // shade, and report "Cleared all notifications".
        final all = await executor.execute('android_dismiss_notification', {
          'deviceSerial': '192.168.1.100:5555',
          'clearAll': true,
        });
        expect(all.isError, isTrue);
        expect(all.content.first.text, contains('not possible over adb'));
      },
    );

    test('android_set_location injects mock coordinates', () async {
      when(
        () => mockAdb.setLocation(
          '192.168.1.100:5555',
          latitude: 10.7769,
          longitude: 106.7009,
        ),
      ).thenAnswer((_) async {});
      when(() => mockAdb.resetLocation('192.168.1.100:5555'))
          .thenAnswer((_) async {});

      final res = await executor.execute('android_set_location', {
        'deviceSerial': '192.168.1.100:5555',
        'latitude': 10.7769,
        'longitude': 106.7009,
      });
      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('Mock location set'));

      final reset = await executor.execute('android_set_location', {
        'deviceSerial': '192.168.1.100:5555',
        'reset': true,
      });
      expect(reset.content.first.text, contains('real location'));
      verify(() => mockAdb.resetLocation('192.168.1.100:5555')).called(1);
    });

    test(
      'an unsupported feature returns its reason, not a generic error',
      () async {
        when(
          () => mockAdb.setLocation(
            '192.168.1.100:5555',
            latitude: 1,
            longitude: 2,
          ),
        ).thenThrow(
          const McpUnsupportedOnDeviceException('needs Android 12 or later'),
        );

        final res = await executor.execute('android_set_location', {
          'deviceSerial': '192.168.1.100:5555',
          'latitude': 1,
          'longitude': 2,
        });
        expect(res.isError, isTrue);
        expect(res.content.first.text, 'needs Android 12 or later');
      },
    );

    test('android_set_network_condition sets network mode', () async {
      when(() => mockAdb.setNetworkCondition('192.168.1.100:5555', 'offline'))
          .thenAnswer((_) async => true);

      final res = await executor.execute('android_set_network_condition', {
        'deviceSerial': '192.168.1.100:5555',
        'mode': 'offline',
      });

      expect(res.isError, isFalse);
      expect(
        res.content.first.text,
        contains('Network condition set on 192.168.1.100:5555: offline'),
      );
    });

    test('android_long_press delegates to client longPress', () async {
      when(
        () => mockAdb.longPress(
          '192.168.1.100:5555',
          rawPoint(0.5, 0.5),
          durationMs: 1500,
        ),
      ).thenAnswer((_) async => true);

      final res = await executor.execute('android_long_press', {
        'deviceSerial': '192.168.1.100:5555',
        'x': 0.5,
        'y': 0.5,
        'durationMs': 1500,
      });

      expect(res.isError, isFalse);
      expect(
        res.content.first.text,
        contains('Long pressed (0.5, 0.5) for 1500ms'),
      );
    });

    test(
      'android_open_notification_panel expands notification shade',
      () async {
        when(
          () => mockAdb.openNotificationPanel(
            '192.168.1.100:5555',
            expand: true,
            quickSettings: false,
          ),
        ).thenAnswer((_) async => true);

        final res = await executor.execute('android_open_notification_panel', {
          'deviceSerial': '192.168.1.100:5555',
          'expand': true,
        });

        expect(res.isError, isFalse);
        expect(res.content.first.text, contains('Opened notification shade'));
      },
    );

    test('android_read_shared_prefs extracts preferences XML', () async {
      when(
        () => mockAdb.readSharedPreferences(
          '192.168.1.100:5555',
          package: 'com.example.app',
          fileName: null,
        ),
      ).thenAnswer(
        (_) async => '<map><string name="token">xyz123</string></map>',
      );

      final res = await executor.execute('android_read_shared_prefs', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.example.app',
      });

      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('token">xyz123'));
    });

    test('android_press_button triggers button event', () async {
      when(() => mockAdb.pressButton('192.168.1.100:5555', 'volume_up'))
          .thenAnswer((_) async => true);

      final res = await executor.execute('android_press_button', {
        'deviceSerial': '192.168.1.100:5555',
        'button': 'volume_up',
      });

      expect(res.isError, isFalse);
      expect(res.content.first.text, contains('Pressed button volume_up'));
    });
  });
}
