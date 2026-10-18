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

  group('McpToolExecutor App & Device Ops Tests', () {
    test(
      'android_get_current_app returns active package and activity',
      () async {
        when(() => mockAdb.getCurrentApp('192.168.1.100:5555')).thenAnswer(
          (_) async => {
            'package': 'com.example.app',
            'activity': '.MainActivity',
          },
        );

        final result = await executor.execute('android_get_current_app', {
          'deviceSerial': '192.168.1.100:5555',
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('com.example.app'));
        expect(result.content.first.text, contains('.MainActivity'));
      },
    );

    test(
      'android_get_current_app warns when the lock screen is in front',
      () async {
        when(() => mockAdb.getCurrentApp('192.168.1.100:5555')).thenAnswer(
          (_) async => {
            'package': 'com.miui.home',
            'activity': 'com.miui.home.launcher.Launcher',
            'overlay': 'StatusBar',
          },
        );

        final result = await executor.execute('android_get_current_app', {
          'deviceSerial': '192.168.1.100:5555',
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('com.miui.home'));
        expect(result.content.first.text, contains('"StatusBar" is in front'));
      },
    );

    test('android_launch_app launches target package', () async {
      when(() => mockAdb.launchApp('192.168.1.100:5555', 'com.spotify.music'))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_launch_app', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.spotify.music',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Application com.spotify.music launched'),
      );
    });

    test('android_stop_app terminates running package', () async {
      when(() => mockAdb.stopApp('192.168.1.100:5555', 'com.spotify.music'))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_stop_app', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.spotify.music',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('com.spotify.music force-stopped'),
      );
    });

    test('android_clear_app_data wipes application state', () async {
      when(() => mockAdb.clearAppData('192.168.1.100:5555', 'com.example.app'))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_clear_app_data', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.example.app',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Application data and cache cleared'),
      );
    });

    test('android_get_clipboard reads system pasteboard', () async {
      when(() => mockAdb.getClipboard('192.168.1.100:5555'))
          .thenAnswer((_) async => 'OTP-987654');

      final result = await executor.execute('android_get_clipboard', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('OTP-987654'));
    });

    test('android_set_clipboard writes text to pasteboard', () async {
      when(() => mockAdb.setClipboard('192.168.1.100:5555', 'NEW_TOKEN'))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_set_clipboard', {
        'deviceSerial': '192.168.1.100:5555',
        'text': 'NEW_TOKEN',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('copied to Android clipboard'),
      );
    });

    test('android_get_device_info returns telemetry dictionary', () async {
      when(() => mockAdb.getDeviceInfo('192.168.1.100:5555')).thenAnswer(
        (_) async => {
          'manufacturer': 'Google',
          'model': 'Pixel 6 Pro',
          'androidVersion': '14',
          'resolution': '1440x3120',
          'batteryLevel': 85,
        },
      );

      final result = await executor.execute('android_get_device_info', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Pixel 6 Pro'));
      expect(result.content.first.text, contains('85'));
    });

    test('android_push_file and pull_file execute successfully', () async {
      when(
        () => mockAdb.pushFile(
          '192.168.1.100:5555',
          '/tmp/a.jpg',
          '/sdcard/Download/a.jpg',
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockAdb.pullFile(
          '192.168.1.100:5555',
          '/sdcard/Download/a.jpg',
          '/tmp/a.jpg',
        ),
      ).thenAnswer((_) async => true);

      final pushRes = await executor.execute('android_push_file', {
        'deviceSerial': '192.168.1.100:5555',
        'localPath': '/tmp/a.jpg',
        'remotePath': '/sdcard/Download/a.jpg',
      });
      expect(pushRes.isError, isFalse);

      final pullRes = await executor.execute('android_pull_file', {
        'deviceSerial': '192.168.1.100:5555',
        'remotePath': '/sdcard/Download/a.jpg',
        'localPath': '/tmp/a.jpg',
      });
      expect(pullRes.isError, isFalse);
    });
  });
}
