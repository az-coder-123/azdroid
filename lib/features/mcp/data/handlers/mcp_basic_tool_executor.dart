import 'dart:convert';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for basic touch, swipe, keyevent, intent, and diagnostics tools.
class McpBasicToolExecutor {
  const McpBasicToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) => const {
    'android_take_screenshot',
    'android_tap',
    'android_double_tap',
    'android_swipe',
    'android_type_text',
    'android_set_text',
    'android_clear_text',
    'android_press_key',
    'android_dispatch_intent',
    'android_get_logcat',
    'android_install_apk',
    'android_drag',
    'android_check_crash',
    'android_scan_media_file',
    'android_shell_command',
  }.contains(toolName);

  static int _resolveKeyCode(String key) {
    return switch (key) {
      'HOME' => 3,
      'BACK' => 4,
      'VOLUME_UP' => 24,
      'VOLUME_DOWN' => 25,
      'POWER' => 26,
      'TAB' => 61,
      'ENTER' => 66,
      'APP_SWITCH' => 187,
      _ => int.tryParse(key) ?? 4,
    };
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_take_screenshot':
        final bytes = await _adb.captureScreenshotBytes(serial);
        if (bytes == null || bytes.isEmpty) {
          return McpToolResult.error(
            'Failed to capture screenshot from $serial.',
          );
        }
        return McpToolResult.image(
          base64Data: base64Encode(bytes),
          caption:
              'Screenshot from device $serial at ${DateTime.now().toIso8601String()}',
        );

      case 'android_tap':
        final x = arguments.getRequiredDouble('x');
        final y = arguments.getRequiredDouble('y');
        final ok = await _adb.tap(serial, x, y);
        return ok
            ? McpToolResult.text('Tapped at coordinates ($x, $y) on $serial.')
            : McpToolResult.error('Failed to tap at ($x, $y).');

      case 'android_double_tap':
        final x = arguments.getRequiredDouble('x');
        final y = arguments.getRequiredDouble('y');
        final interval = arguments.getInt('intervalMs', defaultValue: 120);
        final ok = await _adb.doubleTap(serial, x, y, intervalMs: interval);
        return ok
            ? McpToolResult.text(
                'Double-tapped at coordinates ($x, $y) with ${interval}ms interval on $serial.',
              )
            : McpToolResult.error('Failed to double-tap at ($x, $y).');

      case 'android_swipe':
        final (sx, sy, ex, ey) = _parseCoordinates(arguments);
        final dur = arguments.getInt('durationMs', defaultValue: 300);
        final success = await _adb.swipe(serial, sx, sy, ex, ey, dur);
        return success
            ? McpToolResult.text(
                'Swiped from ($sx, $sy) to ($ex, $ey) on $serial.',
              )
            : McpToolResult.error('Failed to swipe.');

      case 'android_drag':
        final (sx, sy, ex, ey) = _parseCoordinates(arguments);
        final dur = arguments.getInt('durationMs', defaultValue: 1000);
        final success = await _adb.drag(
          serial,
          sx,
          sy,
          ex,
          ey,
          durationMs: dur,
        );
        return success
            ? McpToolResult.text(
                'Dragged from ($sx, $sy) to ($ex, $ey) with duration ${dur}ms on $serial.',
              )
            : McpToolResult.error('Failed to drag.');

      case 'android_type_text':
        final text = arguments.getRequiredString(
          'text',
          aliases: ['input', 'value'],
        );
        final success = await _adb.typeText(serial, text);
        return success
            ? McpToolResult.text('Injected text "$text" into $serial.')
            : McpToolResult.error('Failed to inject text.');

      case 'android_set_text':
        final text = arguments.getRequiredString(
          'text',
          aliases: ['input', 'value'],
        );
        final elementId = arguments.getOptionalInt('elementId');
        final clearFirst = arguments.getBool('clearFirst', defaultValue: false);
        final success = await _adb.setText(
          serial,
          text,
          elementId: elementId,
          clearFirst: clearFirst,
        );
        return success
            ? McpToolResult.text(
                'Set text "$text" on $serial (elementId: ${elementId ?? 'focused'}, clearFirst: $clearFirst).',
              )
            : McpToolResult.error('Failed to set text "$text".');

      case 'android_clear_text':
        final elementId = arguments.getOptionalInt('elementId');
        final success = await _adb.clearText(serial, elementId: elementId);
        return success
            ? McpToolResult.text(
                'Cleared text on $serial (elementId: ${elementId ?? 'focused'}).',
              )
            : McpToolResult.error('Failed to clear text.');

      case 'android_press_key':
        final keyName = arguments
            .getRequiredString('key', aliases: ['keyCode', 'name', 'code'])
            .toUpperCase();
        final code = _resolveKeyCode(keyName);
        final success = await _adb.pressKey(serial, code);
        return success
            ? McpToolResult.text('Pressed key $keyName ($code) on $serial.')
            : McpToolResult.error('Failed to press key $keyName.');

      case 'android_dispatch_intent':
        final action = arguments.getRequiredString('action');
        final uri = arguments.getString('dataUri', aliases: ['uri', 'data']);
        final pkg = arguments.getString('package', aliases: ['pkg']);
        final comp = arguments.getString('component', aliases: ['comp']);
        final rawExtras = arguments['extras'];
        final extras = rawExtras is Map<String, dynamic> ? rawExtras : null;
        final out = await _adb.dispatchIntent(
          serial,
          action,
          dataUri: uri,
          package: pkg,
          component: comp,
          extras: extras,
        );
        return McpToolResult.text('Intent dispatched:\n$out');

      case 'android_get_logcat':
        final limit = arguments.getInt('limit', defaultValue: 50);
        final tag = arguments.getString('tag');
        final logs = await _adb.getLogcat(serial, tag: tag, limit: limit);
        return McpToolResult.text('Logcat dump ($limit lines):\n$logs');

      case 'android_install_apk':
        final apk = arguments.getRequiredString(
          'apkPath',
          aliases: ['path', 'filePath', 'apk'],
        );
        final success = await _adb.installApk(
          serial,
          apk,
          reinstall: arguments.getBool('reinstall', defaultValue: true),
          grantPermissions: arguments.getBool(
            'grantPermissions',
            defaultValue: true,
          ),
        );
        return success
            ? McpToolResult.text('APK installed successfully: $apk')
            : McpToolResult.error('Failed to install APK: $apk');

      case 'android_check_crash':
        final pkg = arguments.getString('package', aliases: ['pkg']);
        final limit = arguments.getInt('limit', defaultValue: 50);
        final crashLogs = await _adb.checkCrash(
          serial,
          package: pkg,
          limit: limit,
        );
        return McpToolResult.text(
          'Crash diagnostics${pkg != null ? ' for $pkg' : ''} (up to $limit entries):\n$crashLogs',
        );

      case 'android_scan_media_file':
        final path = arguments.getRequiredString(
          'filePath',
          aliases: ['path', 'file'],
        );
        final success = await _adb.scanMediaFile(serial, path);
        return success
            ? McpToolResult.text(
                'Triggered MediaStore scan for file: $path on $serial.',
              )
            : McpToolResult.error('Failed to trigger MediaScanner for $path.');

      case 'android_shell_command':
        final cmd = arguments.getRequiredString(
          'command',
          aliases: ['cmd', 'shell'],
        );
        final out = await _adb.shell(serial, cmd);
        return McpToolResult.text('Shell output:\n$out');

      default:
        return McpToolResult.error('Unhandled basic tool: $toolName');
    }
  }

  static (double, double, double, double) _parseCoordinates(
    Map<String, dynamic> arguments,
  ) {
    return (
      arguments.getRequiredDouble('startX', aliases: ['x1', 'fromX']),
      arguments.getRequiredDouble('startY', aliases: ['y1', 'fromY']),
      arguments.getRequiredDouble('endX', aliases: ['x2', 'toX']),
      arguments.getRequiredDouble('endY', aliases: ['y2', 'toY']),
    );
  }
}
