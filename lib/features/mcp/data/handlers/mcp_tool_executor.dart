import 'dart:convert';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Coordinates and executes MCP tool calls against Android devices using pure Dart.
class McpToolExecutor {
  McpToolExecutor({McpAdbClient? adbClient})
      : _adb = adbClient ?? McpAdbClient();

  final McpAdbClient _adb;

  Future<String?> _resolveDevice(String? providedSerial) async {
    if (providedSerial != null && providedSerial.trim().isNotEmpty) {
      return providedSerial.trim();
    }
    final serials = await _adb.getConnectedSerials();
    return serials.isNotEmpty ? serials.first : null;
  }

  Future<McpToolResult> execute(String toolName, Map<String, dynamic> arguments) async {
    try {
      if (toolName == 'android_list_devices') {
        final raw = await _adb.listDevicesRaw();
        return raw.isNotEmpty
            ? McpToolResult.text('Attached Android Devices:\n$raw')
            : McpToolResult.text('No attached Android devices detected via ADB.');
      }

      final serial = await _resolveDevice(arguments['deviceSerial'] as String?);
      if (serial == null) {
        return McpToolResult.error('No connected Android device found via ADB.');
      }

      switch (toolName) {
        case 'android_take_screenshot':
          final bytes = await _adb.captureScreenshotBytes(serial);
          if (bytes == null || bytes.isEmpty) {
            return McpToolResult.error('Failed to capture screenshot from $serial.');
          }
          return McpToolResult.image(
            base64Data: base64Encode(bytes),
            caption: 'Screenshot from device $serial at ${DateTime.now().toIso8601String()}',
          );

        case 'android_tap':
          final x = (arguments['x'] as num).toDouble();
          final y = (arguments['y'] as num).toDouble();
          final success = await _adb.tap(serial, x, y);
          return success
              ? McpToolResult.text('Tapped at coordinates ($x, $y) on $serial.')
              : McpToolResult.error('Failed to tap at ($x, $y).');

        case 'android_swipe':
          final sx = (arguments['startX'] as num).toDouble();
          final sy = (arguments['startY'] as num).toDouble();
          final ex = (arguments['endX'] as num).toDouble();
          final ey = (arguments['endY'] as num).toDouble();
          final dur = arguments['durationMs'] as int? ?? 300;
          final success = await _adb.swipe(serial, sx, sy, ex, ey, dur);
          return success
              ? McpToolResult.text('Swiped from ($sx, $sy) to ($ex, $ey) on $serial.')
              : McpToolResult.error('Failed to swipe.');

        case 'android_type_text':
          final text = arguments['text'] as String;
          final success = await _adb.typeText(serial, text);
          return success
              ? McpToolResult.text('Injected text "$text" into $serial.')
              : McpToolResult.error('Failed to inject text.');

        case 'android_press_key':
          final keyMap = <String, int>{
            'HOME': 3,
            'BACK': 4,
            'VOLUME_UP': 24,
            'VOLUME_DOWN': 25,
            'POWER': 26,
            'TAB': 61,
            'ENTER': 66,
            'APP_SWITCH': 187,
          };
          final keyName = (arguments['key'] as String).toUpperCase();
          final code = keyMap[keyName] ?? 4;
          final success = await _adb.pressKey(serial, code);
          return success
              ? McpToolResult.text('Pressed key $keyName ($code) on $serial.')
              : McpToolResult.error('Failed to press key $keyName.');

        case 'android_dispatch_intent':
          final action = arguments['action'] as String;
          final uri = arguments['dataUri'] as String?;
          final pkg = arguments['package'] as String?;
          final comp = arguments['component'] as String?;
          final extras = arguments['extras'] is Map<String, dynamic>
              ? arguments['extras'] as Map<String, dynamic>
              : null;
          final out = await _adb.dispatchIntent(serial, action, dataUri: uri, package: pkg, component: comp, extras: extras);
          return McpToolResult.text('Intent dispatched:\n$out');

        case 'android_get_logcat':
          final limit = arguments['limit'] as int? ?? 50;
          final tag = arguments['tag'] as String?;
          final logs = await _adb.getLogcat(serial, tag: tag, limit: limit);
          return McpToolResult.text('Logcat dump ($limit lines):\n$logs');

        case 'android_install_apk':
          final apk = arguments['apkPath'] as String;
          final reinstall = arguments['reinstall'] as bool? ?? true;
          final grant = arguments['grantPermissions'] as bool? ?? true;
          final success = await _adb.installApk(serial, apk, reinstall: reinstall, grantPermissions: grant);
          return success
              ? McpToolResult.text('APK installed successfully: $apk')
              : McpToolResult.error('Failed to install APK: $apk');

        case 'android_shell_command':
          final cmd = arguments['command'] as String;
          final out = await _adb.shell(serial, cmd);
          return McpToolResult.text('Shell output:\n$out');

        default:
          return McpToolResult.error('Unknown tool: $toolName');
      }
    } catch (e) {
      return McpToolResult.error('Tool execution exception: $e');
    }
  }
}
