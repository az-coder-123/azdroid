import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
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
          return McpToolResult.text('No active notifications found on $serial.');
        }
        final buf = StringBuffer(
          'Active Notifications on $serial (${notifs.length}):\n',
        );
        for (final n in notifs) {
          buf.writeln('• [${n['package']}] ${n['title']}: ${n['text']}');
        }
        return McpToolResult.text(buf.toString().trim());

      case 'android_dismiss_notification':
        final key = arguments.getString(
          'key',
          aliases: ['id', 'notificationKey'],
        );
        final clearAll = arguments.getBool(
          'clearAll',
          aliases: ['all'],
          defaultValue: false,
        );
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
        final lat = arguments.getRequiredDouble('latitude', aliases: ['lat']);
        final lng = arguments.getRequiredDouble(
          'longitude',
          aliases: ['lng', 'lon'],
        );
        final alt = arguments.getOptionalDouble('altitude', aliases: ['alt']);
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
        final mode = arguments.getRequiredString(
          'mode',
          aliases: ['condition', 'networkMode', 'network'],
        );
        final ok = await _adb.setNetworkCondition(serial, mode);
        return ok
            ? McpToolResult.text('Network condition set on $serial: $mode')
            : McpToolResult.error('Failed to set network condition.');

      case 'android_long_press':
        final (x, y) = arguments.getPointPair();
        final duration = arguments.getInt(
          'durationMs',
          aliases: ['duration', 'timeMs', 'delayMs'],
          defaultValue: 1000,
        );
        final ok = await _adb.longPress(serial, x, y, durationMs: duration);
        return ok
            ? McpToolResult.text(
                'Long pressed ($x, $y) for ${duration}ms on $serial.',
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
