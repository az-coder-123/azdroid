import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for smart waiting, macro batching, notifications, mock location,
/// network conditioning, and hardware button tools.
class McpAutomationToolExecutor {
  const McpAutomationToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
      'android_wait_for_element',
      'android_batch_actions',
      'android_get_notifications',
      'android_dismiss_notification',
      'android_set_location',
      'android_set_network_condition',
      'android_long_press',
      'android_open_notification_panel',
      'android_read_shared_prefs',
      'android_press_button',
    }.contains(toolName);
  }

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_wait_for_element':
        final text = arguments['text'] as String?;
        final resId = arguments['resourceId'] as String?;
        final desc = arguments['contentDesc'] as String?;
        final timeout = (arguments['timeoutMs'] as int?) ?? 10000;
        final poll = (arguments['pollIntervalMs'] as int?) ?? 500;
        final res = await _adb.waitForElement(
          serial,
          text: text,
          resourceId: resId,
          contentDesc: desc,
          timeoutMs: timeout,
          pollIntervalMs: poll,
        );
        if (res == null) {
          return McpToolResult.error('Element timed out after ${timeout}ms.');
        }
        return McpToolResult.text(
          'Element appeared (${res['elapsedMs']}ms):\n$res',
        );

      case 'android_batch_actions':
        final list =
            (arguments['actions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final res = await _adb.batchActions(serial, list);
        return McpToolResult.text(
          'Executed ${res.length} batch actions on $serial:\n$res',
        );

      case 'android_get_notifications':
        final filter = arguments['filter'] as String?;
        final notifs = await _adb.getNotifications(serial, filter: filter);
        if (notifs.isEmpty) {
          return McpToolResult.text(
            'No active notifications found on $serial.',
          );
        }
        final buf = StringBuffer(
          'Active Notifications on $serial (${notifs.length}):\n',
        );
        for (final n in notifs) {
          buf.writeln('• [${n['package']}] ${n['title']}: ${n['text']}');
        }
        return McpToolResult.text(buf.toString().trim());

      case 'android_dismiss_notification':
        final key = arguments['key'] as String?;
        final clearAll = (arguments['clearAll'] as bool?) ?? false;
        final ok = await _adb.dismissNotification(
          serial,
          key: key,
          clearAll: clearAll,
        );
        return ok
            ? McpToolResult.text(
                clearAll
                    ? 'Cleared all notifications.'
                    : 'Dismissed notification: $key',
              )
            : McpToolResult.error('Failed to dismiss notification.');

      case 'android_set_location':
        final lat = (arguments['latitude'] as num).toDouble();
        final lng = (arguments['longitude'] as num).toDouble();
        final alt = (arguments['altitude'] as num?)?.toDouble();
        final ok = await _adb.setLocation(
          serial,
          latitude: lat,
          longitude: lng,
          altitude: alt,
        );
        return ok
            ? McpToolResult.text('Mock location set on $serial: ($lat, $lng)')
            : McpToolResult.error('Failed to set mock location.');

      case 'android_set_network_condition':
        final mode = arguments['mode'] as String;
        final ok = await _adb.setNetworkCondition(serial, mode);
        return ok
            ? McpToolResult.text('Network condition set on $serial: $mode')
            : McpToolResult.error('Failed to set network condition.');

      case 'android_long_press':
        final x = (arguments['x'] as num).toDouble();
        final y = (arguments['y'] as num).toDouble();
        final duration = (arguments['durationMs'] as int?) ?? 1000;
        final ok = await _adb.longPress(serial, x, y, durationMs: duration);
        return ok
            ? McpToolResult.text(
                'Long pressed ($x, $y) for ${duration}ms on $serial.',
              )
            : McpToolResult.error('Failed to inject long press.');

      case 'android_open_notification_panel':
        final expand = (arguments['expand'] as bool?) ?? true;
        final qs = (arguments['quickSettings'] as bool?) ?? false;
        final ok = await _adb.openNotificationPanel(
          serial,
          expand: expand,
          quickSettings: qs,
        );
        return ok
            ? McpToolResult.text(
                expand
                    ? (qs
                          ? 'Opened Quick Settings.'
                          : 'Opened notification shade.')
                    : 'Collapsed panels.',
              )
            : McpToolResult.error('Failed to toggle notification panel.');

      case 'android_read_shared_prefs':
        final pkg = arguments['package'] as String;
        final file = arguments['fileName'] as String?;
        final content = await _adb.readSharedPreferences(
          serial,
          package: pkg,
          fileName: file,
        );
        return McpToolResult.text('SharedPreferences for $pkg:\n$content');

      case 'android_press_button':
        final btn = arguments['button'] as String;
        final ok = await _adb.pressButton(serial, btn);
        return ok
            ? McpToolResult.text('Pressed button $btn on $serial.')
            : McpToolResult.error(
                'Failed to press button $btn or invalid button.',
              );

      default:
        return McpToolResult.error('Unknown tool: $toolName');
    }
  }
}
