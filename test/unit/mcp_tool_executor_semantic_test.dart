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

  group('McpToolExecutor Semantic & System Ops Tests', () {
    test('android_dump_hierarchy returns accessibility tree XML', () async {
      when(() => mockAdb.dumpHierarchy('192.168.1.100:5555')).thenAnswer(
        (_) async => '<hierarchy><node text="Login" bounds="[10,20][100,50]"/></hierarchy>',
      );

      final result = await executor.execute('android_dump_hierarchy', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('<hierarchy>'));
      expect(result.content.first.text, contains('Login'));
    });

    test('android_get_semantic_tree returns pruned digest', () async {
      when(() => mockAdb.getSemanticTree('192.168.1.100:5555')).thenAnswer(
        (_) async => '=== Screen UI Tree (1 elements) ===\n[#1] Button text:"OK" center:(100,200)',
      );

      final result = await executor.execute('android_get_semantic_tree', {
        'deviceSerial': '192.168.1.100:5555',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('[#1] Button'));
    });

    test('android_click_element_by_id taps element by id', () async {
      when(() => mockAdb.clickElementById('192.168.1.100:5555', 1))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_click_element_by_id', {
        'deviceSerial': '192.168.1.100:5555',
        'id': 1,
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Successfully tapped element [#1]'),
      );
    });

    test(
      'android_find_element returns element coordinates and metadata',
      () async {
        when(
          () => mockAdb.findElement(
            '192.168.1.100:5555',
            text: 'Submit',
            resourceId: any(named: 'resourceId'),
            contentDesc: any(named: 'contentDesc'),
          ),
        ).thenAnswer(
          (_) async => {
            'text': 'Submit',
            'bounds': '[100,200][300,250]',
            'centerPixels': {'x': 200, 'y': 225},
            'normalized': {'x': 0.1852, 'y': 0.0938},
          },
        );

        final result = await executor.execute('android_find_element', {
          'deviceSerial': '192.168.1.100:5555',
          'text': 'Submit',
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('Submit'));
        expect(result.content.first.text, contains('[100,200][300,250]'));
      },
    );

    test('android_click_element triggers element search and tap', () async {
      when(
        () => mockAdb.clickElement(
          '192.168.1.100:5555',
          text: 'Login',
          resourceId: any(named: 'resourceId'),
          contentDesc: any(named: 'contentDesc'),
        ),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_click_element', {
        'deviceSerial': '192.168.1.100:5555',
        'text': 'Login',
      });

      expect(result.isError, isFalse);
      expect(
        result.content.first.text,
        contains('Clicked element on 192.168.1.100:5555'),
      );
    });

    test('android_toggle_wifi toggles Wi-Fi state', () async {
      when(() => mockAdb.toggleWifi('192.168.1.100:5555', true))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_toggle_wifi', {
        'deviceSerial': '192.168.1.100:5555',
        'enable': true,
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Wi-Fi enabled'));
    });

    test('android_toggle_airplane_mode toggles Airplane mode', () async {
      when(() => mockAdb.toggleAirplaneMode('192.168.1.100:5555', false))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_toggle_airplane_mode', {
        'deviceSerial': '192.168.1.100:5555',
        'enable': false,
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Airplane mode disabled'));
    });

    test(
      'android_grant_permission and revoke_permission execute successfully',
      () async {
        when(
          () => mockAdb.grantPermission(
            '192.168.1.100:5555',
            'com.example.app',
            'android.permission.CAMERA',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockAdb.revokePermission(
            '192.168.1.100:5555',
            'com.example.app',
            'android.permission.CAMERA',
          ),
        ).thenAnswer((_) async => true);

        final grantRes = await executor.execute('android_grant_permission', {
          'deviceSerial': '192.168.1.100:5555',
          'package': 'com.example.app',
          'permission': 'android.permission.CAMERA',
        });
        expect(grantRes.isError, isFalse);
        expect(grantRes.content.first.text, contains('granted'));

        final revokeRes = await executor.execute('android_revoke_permission', {
          'deviceSerial': '192.168.1.100:5555',
          'package': 'com.example.app',
          'permission': 'android.permission.CAMERA',
        });
        expect(revokeRes.isError, isFalse);
        expect(revokeRes.content.first.text, contains('revoked'));
      },
    );

    test('android_set_volume adjusts stream volume index', () async {
      when(
        () =>
            mockAdb.setVolume('192.168.1.100:5555', stream: 3, volumeIndex: 10),
      ).thenAnswer((_) async => true);

      final result = await executor.execute('android_set_volume', {
        'deviceSerial': '192.168.1.100:5555',
        'stream': 3,
        'volumeIndex': 10,
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('volume set to 10'));
    });

    test('android_wake_screen turns screen on/off', () async {
      when(() => mockAdb.wakeOrSleep('192.168.1.100:5555', true))
          .thenAnswer((_) async => true);

      final result = await executor.execute('android_wake_screen', {
        'deviceSerial': '192.168.1.100:5555',
        'wake': true,
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('woken up'));
    });

    test('android_open_settings launches settings page', () async {
      when(
        () => mockAdb.openSettings(
          '192.168.1.100:5555',
          action: 'android.settings.WIFI_SETTINGS',
          packageName: null,
        ),
      ).thenAnswer(
        (_) async => 'Starting: Intent { act=android.settings.WIFI_SETTINGS }',
      );

      final result = await executor.execute('android_open_settings', {
        'deviceSerial': '192.168.1.100:5555',
        'action': 'android.settings.WIFI_SETTINGS',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Settings launched'));
    });
  });
}
