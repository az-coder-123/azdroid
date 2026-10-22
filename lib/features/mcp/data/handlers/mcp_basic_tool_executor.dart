import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_text_entry.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point_arguments.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for basic touch, swipe, pinch, keyevent, intent, and diagnostics tools.
class McpBasicToolExecutor {
  const McpBasicToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) => const {
    'android_tap',
    'android_double_tap',
    'android_swipe',
    'android_drag',
    'android_scroll',
    'android_type_text',
    'android_set_text',
    'android_clear_text',
    'android_press_key',
    'android_dispatch_intent',
    'android_get_logcat',
    'android_install_apk',
    'android_check_crash',
    'android_scan_media_file',
    'android_shell_command',
  }.contains(toolName);

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_tap':
        final point = arguments.getPoint();
        final verify = arguments.getBool(
          'verifyChange',
          aliases: ['verify_change', 'verify'],
        );

        if (!verify) {
          final ok = await _adb.tap(serial, point);
          return ok
              ? McpToolResult.text('Tapped at coordinates $point on $serial.')
              : McpToolResult.error('Failed to tap at $point.');
        }

        final delayMs = arguments.getInt(
          'verifyDelayMs',
          aliases: ['delayMs', 'waitMs'],
          defaultValue: 300,
        );
        final (ok, stateChanged) = await _adb.tapAndVerify(
          serial,
          point,
          delayMs: delayMs,
        );

        if (!ok) {
          return McpToolResult.error('Failed to tap at $point.');
        }

        if (stateChanged) {
          return McpToolResult.text(
            'Tapped at coordinates $point on $serial. State change verified (UI updated).',
          );
        }

        return McpToolResult.text(
          'Tapped at coordinates $point on $serial.\n'
          'Warning: Tap produced no detectable UI change. '
          'The target may be non-clickable, obscured, or out of active bounds.',
        );

      case 'android_double_tap':
        final point = arguments.getPoint();
        final interval = arguments.getInt('intervalMs', defaultValue: 120);
        final ok = await _adb.doubleTap(serial, point, intervalMs: interval);
        return ok
            ? McpToolResult.text(
                'Double-tapped at coordinates $point with ${interval}ms interval on $serial.',
              )
            : McpToolResult.error('Failed to double-tap at $point.');

      case 'android_swipe':
        final (start, end) = _parseCoordinates(arguments);
        final dur = arguments.getInt('durationMs', defaultValue: 300);
        final ok = await _adb.swipe(serial, start, end, dur);
        return ok
            ? McpToolResult.text('Swiped from $start to $end on $serial.')
            : McpToolResult.error('Failed to swipe.');

      case 'android_drag':
        final (start, end) = _parseCoordinates(arguments);
        final dur = arguments.getInt('durationMs', defaultValue: 1000);
        final ok = await _adb.drag(serial, start, end, durationMs: dur);
        return ok
            ? McpToolResult.text(
                'Dragged from $start to $end with duration ${dur}ms on $serial.',
              )
            : McpToolResult.error('Failed to drag.');

      case 'android_scroll':
        final dir =
            arguments.getString('direction', aliases: ['dir']) ?? 'down';
        final dist =
            arguments.getOptionalDouble('distance', aliases: ['dist']) ?? 0.6;
        final spd =
            arguments.getString('speed', aliases: ['velocity']) ?? 'normal';
        final dur = arguments.getOptionalInt(
          'durationMs',
          aliases: ['duration'],
        );
        final start = arguments.getOptionalPoint(
          xKey: 'startX',
          yKey: 'startY',
          xAliases: ['sx', 'x1'],
          yAliases: ['sy', 'y1'],
        );
        final end = arguments.getOptionalPoint(
          xKey: 'endX',
          yKey: 'endY',
          xAliases: ['ex', 'x2'],
          yAliases: ['ey', 'y2'],
        );
        final ok = await _adb.scroll(
          serial,
          direction: dir,
          distance: dist,
          speed: spd,
          start: start,
          end: end,
          durationMs: dur,
        );
        return ok
            ? McpToolResult.text(
                'Scrolled $dir ($spd, distance: $dist) on $serial.',
              )
            : McpToolResult.error('Failed to scroll $dir on $serial.');

      case 'android_type_text':
        final text = arguments.getRequiredString(
          'text',
          aliases: ['input', 'value'],
        );
        final ok = await _adb.typeText(serial, text);
        return ok
            ? McpToolResult.text('Injected text "$text" into $serial.')
            : McpToolResult.error('Failed to inject text.');

      case 'android_set_text':
        final text = arguments.getRequiredString(
          'text',
          aliases: ['input', 'value'],
        );
        final id = arguments.getOptionalInt('elementId');
        final clear = arguments.getBool('clearFirst', defaultValue: false);
        final entry = await _adb.setText(
          serial,
          text,
          elementId: id,
          clearFirst: clear,
        );
        final target = 'elementId: ${id ?? 'focused'}, clearFirst: $clear';
        return switch (entry) {
          McpTextEntry.pasted => McpToolResult.text(
            'Set text "$text" on $serial by pasting ($target).',
          ),
          McpTextEntry.typed => McpToolResult.text(
            'Typed text "$text" on $serial ($target). The clipboard is not '
            'available on this device, so it was typed as key events; an '
            'active IME such as Telex may have altered it.',
          ),
          McpTextEntry.failed => McpToolResult.error(
            'Failed to set text "$text" ($target).',
          ),
        };

      case 'android_clear_text':
        final id = arguments.getOptionalInt('elementId');
        final ok = await _adb.clearText(serial, elementId: id);
        return ok
            ? McpToolResult.text(
                'Cleared text on $serial (elementId: ${id ?? 'focused'}).',
              )
            : McpToolResult.error('Failed to clear text.');

      case 'android_press_key':
        final keyName = arguments
            .getRequiredString('key', aliases: ['keyCode', 'name', 'code'])
            .toUpperCase();
        final code = McpAdbTextOps.resolveKeyCode(keyName);
        final success = await _adb.pressKey(serial, code);
        return success
            ? McpToolResult.text('Pressed key $keyName ($code) on $serial.')
            : McpToolResult.error('Failed to press key $keyName.');

      case 'android_dispatch_intent':
        final raw = arguments['extras'];
        final out = await _adb.dispatchIntent(
          serial,
          arguments.getRequiredString('action'),
          dataUri: arguments.getString('dataUri', aliases: ['uri', 'data']),
          package: arguments.getString('package', aliases: ['pkg']),
          component: arguments.getString('component', aliases: ['comp']),
          extras: raw is Map<String, dynamic> ? raw : null,
        );
        return McpToolResult.text('Intent dispatched:\n$out');

      case 'android_get_logcat':
        final limit = arguments.getInt('limit', defaultValue: 50);
        final tag = arguments.getString('tag');
        final level = arguments.getString('level', aliases: ['priority']);
        final logs = await _adb.getLogcat(
          serial,
          tag: tag,
          level: level,
          limit: limit,
        );
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
        final logs = await _adb.checkCrash(serial, package: pkg, limit: limit);
        return McpToolResult.text(
          'Crash diagnostics${pkg != null ? ' for $pkg' : ''} (up to $limit entries):\n$logs',
        );

      case 'android_scan_media_file':
        final path = arguments.getRequiredString(
          'filePath',
          aliases: ['path', 'file'],
        );
        final ok = await _adb.scanMediaFile(serial, path);
        return ok
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

  static (McpPoint, McpPoint) _parseCoordinates(
    Map<String, dynamic> arguments,
  ) {
    final start = arguments.getPoint(
      xKey: 'startX',
      yKey: 'startY',
      xAliases: ['x1', 'fromX'],
      yAliases: ['y1', 'fromY'],
    );
    final end = arguments.getPoint(
      xKey: 'endX',
      yKey: 'endY',
      xAliases: ['x2', 'toX'],
      yAliases: ['y2', 'toY'],
    );
    return (start, end);
  }
}
