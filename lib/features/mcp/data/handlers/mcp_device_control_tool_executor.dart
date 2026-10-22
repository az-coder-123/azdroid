import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point_arguments.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for notifications, mock location, network conditioning,
/// shared preferences, and hardware button tools.
class McpDeviceControlToolExecutor {
  const McpDeviceControlToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) {
    return const {
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

  /// How long android_dismiss_notification hides a notification by default.
  static const int _defaultHideMinutes = 60;

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    try {
      return await _executeInternal(toolName, serial, arguments);
    } on McpArgumentException catch (e) {
      return McpToolResult.error(e.message);
    }
  }

  Future<McpToolResult> _executeInternal(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_get_notifications':
        final filter = arguments.getString(
          'filter',
          aliases: ['package', 'pkg', 'query'],
        );
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
          buf.writeln(
            '• [${n['package']}] ${n['title']}: ${n['text']}\n'
            '  key: ${n['key']}',
          );
        }
        return McpToolResult.text(buf.toString().trim());

      case 'android_dismiss_notification':
        if (arguments.getBool('clearAll', aliases: ['all'])) {
          return McpToolResult.error(
            'Clearing all notifications is not possible over adb. Hide them '
            'one by one with the key from android_get_notifications.',
          );
        }
        final key = arguments.getRequiredString(
          'key',
          aliases: ['id', 'notificationKey'],
        );
        final minutes = arguments.getInt(
          'hideMinutes',
          aliases: ['minutes'],
          defaultValue: _defaultHideMinutes,
        );
        final ok = await _adb.snoozeNotification(
          serial,
          key: key,
          hideFor: Duration(minutes: minutes),
        );
        return ok
            ? McpToolResult.text(
                'Hid notification $key for $minutes minutes (snoozed; it '
                'comes back afterwards).',
              )
            : McpToolResult.error('Failed to hide notification $key.');

      case 'android_set_location':
        if (arguments.getBool('reset', aliases: ['clear', 'restore'])) {
          await _adb.resetLocation(serial);
          return McpToolResult.text(
            'Mock location removed on $serial; it reports its real location '
            'again.',
          );
        }
        final lat = arguments.getRequiredDouble('latitude', aliases: ['lat']);
        final lng = arguments.getRequiredDouble(
          'longitude',
          aliases: ['lng', 'lon'],
        );
        await _adb.setLocation(serial, latitude: lat, longitude: lng);
        return McpToolResult.text(
          'Mock location set on $serial: ($lat, $lng). It applies to every '
          'app until android_set_location is called with reset: true.',
        );

      case 'android_set_network_condition':
        final mode = arguments.getRequiredString(
          'mode',
          aliases: ['condition', 'networkMode', 'network'],
        );
        final ok = await _adb.setNetworkCondition(serial, mode);
        return ok
            ? McpToolResult.text('Network condition set on $serial: $mode')
            : McpToolResult.error('Failed to set network condition.');

      case 'android_long_press':
        final point = arguments.getPoint();
        final duration = arguments.getInt(
          'durationMs',
          aliases: ['duration', 'timeMs', 'delayMs'],
          defaultValue: 1000,
        );
        final ok = await _adb.longPress(serial, point, durationMs: duration);
        return ok
            ? McpToolResult.text(
                'Long pressed $point for ${duration}ms on $serial.',
              )
            : McpToolResult.error('Failed to inject long press.');

      case 'android_open_notification_panel':
        final expand = arguments.getBool(
          'expand',
          aliases: ['open'],
          defaultValue: true,
        );
        final qs = arguments.getBool(
          'quickSettings',
          aliases: ['qs'],
          defaultValue: false,
        );
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
        final pkg = arguments.getRequiredString(
          'package',
          aliases: ['pkg', 'packageName', 'app'],
        );
        final file = arguments.getString('fileName', aliases: ['file', 'name']);
        final content = await _adb.readSharedPreferences(
          serial,
          package: pkg,
          fileName: file,
        );
        return McpToolResult.text('SharedPreferences for $pkg:\n$content');

      case 'android_press_button':
        final btn = arguments.getRequiredString(
          'button',
          aliases: ['btn', 'key', 'name'],
        );
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
