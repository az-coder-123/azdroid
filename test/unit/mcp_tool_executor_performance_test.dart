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

  group('McpToolExecutor Performance & Media Ops Tests', () {
    test('android_get_cpu_usage returns CPU utilization metrics', () async {
      when(
        () => mockAdb.getCpuUsage(
          '192.168.1.100:5555',
          package: 'com.example.app',
        ),
      ).thenAnswer(
        (_) async => '15% 1234/com.example.app: 10% user + 5% kernel',
      );

      final result = await executor.execute('android_get_cpu_usage', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.example.app',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('15% 1234/com.example.app'));
    });

    test(
      'android_get_memory_info returns PSS and Dalvik heap breakdown',
      () async {
        when(
          () => mockAdb.getMemoryInfo('192.168.1.100:5555', 'com.example.app'),
        ).thenAnswer(
          (_) async =>
              'TOTAL PSS: 45210 kB, Native Heap: 12000 kB, Dalvik: 18000 kB',
        );

        final result = await executor.execute('android_get_memory_info', {
          'deviceSerial': '192.168.1.100:5555',
          'package': 'com.example.app',
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('TOTAL PSS: 45210 kB'));
      },
    );

    test(
      'android_get_battery_stats returns temperature and health dictionary',
      () async {
        when(() => mockAdb.getBatteryStats('192.168.1.100:5555')).thenAnswer(
          (_) async => {
            'level': 88,
            'voltageMv': 4120,
            'temperatureCelsius': 29.5,
            'technology': 'Li-poly',
            'acPowered': false,
          },
        );

        final result = await executor.execute('android_get_battery_stats', {
          'deviceSerial': '192.168.1.100:5555',
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('88'));
        expect(result.content.first.text, contains('29.5'));
      },
    );

    test('android_get_gfx_info queries frame render timings', () async {
      when(() => mockAdb.getGfxInfo('192.168.1.100:5555', 'com.example.app'))
          .thenAnswer(
            (_) async =>
                'Total frames rendered: 1200\nJanky frames: 12 (1.00%)',
          );

      final result = await executor.execute('android_get_gfx_info', {
        'deviceSerial': '192.168.1.100:5555',
        'package': 'com.example.app',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Total frames rendered: 1200'),
      );
    });

    test('android_get_network_info extracts IP and link speed', () async {
      when(() => mockAdb.getNetworkInfo('192.168.1.100:5555')).thenAnswer(
        (_) async => {
          'ipAddress': '192.168.1.100',
          'ssid': 'DeskDroid_5G',
          'linkSpeed': '433 Mbps',
        },
      );

      final result = await executor.execute('android_get_network_info', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('192.168.1.100'));
      expect(result.content.first.text, contains('DeskDroid_5G'));
    });

    test(
      'android_record_screen triggers video capture and file pull',
      () async {
        when(
          () => mockAdb.recordScreen(
            '192.168.1.100:5555',
            durationSec: 5,
            localDestination: '/tmp/test_rec.mp4',
          ),
        ).thenAnswer((_) async => true);

        final result = await executor.execute('android_record_screen', {
          'deviceSerial': '192.168.1.100:5555',
          'durationSec': 5,
          'localDestination': '/tmp/test_rec.mp4',
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('saved to /tmp/test_rec.mp4'),
        );
      },
    );

    test('android_list_processes and kill_process work as expected', () async {
      when(
        () => mockAdb.listProcesses(
          '192.168.1.100:5555',
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async => [
          {'pid': '1234', 'name': 'com.example.app'},
          {'pid': '5678', 'name': 'com.android.chrome'},
        ],
      );
      when(
        () =>
            mockAdb.killProcess('192.168.1.100:5555', pid: 1234, package: null),
      ).thenAnswer((_) async => true);

      final listRes = await executor.execute('android_list_processes', {
        'deviceSerial': '192.168.1.100:5555',
      });
      expect(listRes.isError, isFalse);
      expect(listRes.content.first.text, contains('1234'));

      final killRes = await executor.execute('android_kill_process', {
        'deviceSerial': '192.168.1.100:5555',
        'pid': 1234,
      });
      expect(killRes.isError, isFalse);
      expect(killRes.content.first.text, contains('Terminated process 1234'));
    });

    test('android_set_orientation forces screen rotation', () async {
      when(() => mockAdb.setOrientation('192.168.1.100:5555', 1))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_set_orientation', {
        'deviceSerial': '192.168.1.100:5555',
        'orientation': 1,
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Landscape (90°)'));
    });

    test(
      'android_simulate_biometric dispatches biometric simulation',
      () async {
        when(
          () => mockAdb.simulateBiometric('192.168.1.100:5555', success: true),
        ).thenAnswer((_) async => true);

        final result = await executor.execute('android_simulate_biometric', {
          'deviceSerial': '192.168.1.100:5555',
          'success': true,
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('Success'));
      },
    );
  });
}
