import 'package:desk_droid/features/mcp/data/handlers/mcp_operations_by_tool.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';

/// An executor operation (one of the device-tested handlers) and its
/// arguments.
typedef McpOperation = ({String name, Map<String, dynamic> arguments});

/// Maps the published, consolidated tools onto the executor operations.
///
/// The catalog stays under the ~40-tool limit some clients apply (Cursor),
/// while every operation keeps its tested handler. Names that are not
/// consolidated tools — the 19 unchanged tools and every pre-consolidation
/// name such as `android_double_tap` — pass through unchanged, so older
/// configurations and prompts keep working.
class McpToolRouter {
  const McpToolRouter._();

  /// Every operation a published tool can reach, for the catalog guard.
  static const Map<String, Set<String>> operationsByTool = mcpOperationsByTool;

  /// `android_wait_for_condition` conditions read from screenshots.
  static const Set<String> screenConditions = {
    'image_present',
    'screen_changed',
  };

  /// `android_press_key` keys that press a hardware button.
  static const Set<String> buttonKeys = {
    'MUTE',
    'CAMERA',
    'WAKEUP',
    'SLEEP',
    'MEDIA_PLAY_PAUSE',
    'MEDIA_NEXT',
    'MEDIA_PREV',
  };

  /// `android_press_key` keys that open or close the status bar panels.
  static const Map<String, ({bool expand, bool quickSettings})> panelKeys = {
    'NOTIFICATIONS': (expand: true, quickSettings: false),
    'QUICK_SETTINGS': (expand: true, quickSettings: true),
    'CLOSE_PANELS': (expand: false, quickSettings: false),
  };

  /// `android_get_device_stats` kinds and their operations.
  static const Map<String, String> statsOperations = {
    'device': 'android_get_device_info',
    'battery': 'android_get_battery_stats',
    'network': 'android_get_network_info',
    'cpu': 'android_get_cpu_usage',
    'memory': 'android_get_memory_info',
    'gfx': 'android_get_gfx_info',
    'fps': 'android_get_frame_rate',
    'thermal': 'android_get_thermal',
  };

  /// `android_set_network` modes handled by the radio toggles.
  static const Map<String, (String, bool)> radioModes = {
    'wifi_on': ('android_toggle_wifi', true),
    'wifi_off': ('android_toggle_wifi', false),
    'airplane_on': ('android_toggle_airplane_mode', true),
    'airplane_off': ('android_toggle_airplane_mode', false),
  };

  static McpOperation route(String tool, Map<String, dynamic> args) {
    McpOperation to(String name, [Map<String, dynamic> extra = const {}]) =>
        (name: name, arguments: {...args, ...extra});
    switch (tool) {
      case 'android_tap':
        final hold = args.getOptionalInt('holdMs', aliases: ['holdDurationMs']);
        final taps = args.getInt('taps', aliases: ['count'], defaultValue: 1);
        if (hold != null && hold > 0) {
          if (taps > 1) _invalid('Use taps or holdMs, not both.');
          return to('android_long_press', {'durationMs': hold});
        }
        return to(taps == 2 ? 'android_double_tap' : 'android_tap');
      case 'android_swipe':
        if (args.getString('direction') != null) return to('android_scroll');
        return to(
          args.getString('style') == 'drag' ? 'android_drag' : 'android_swipe',
        );
      case 'android_multitouch_gesture':
        return switch (args.getRequiredString('gesture')) {
          'pinch' => to('android_pinch_gesture'),
          'rotate' => to('android_rotate_gesture'),
          final other => _invalid('Unknown gesture "$other" (pinch, rotate).'),
        };
      case 'android_input_text':
        final text = args.getOptionalText('text') ?? '';
        if (text.isEmpty) return to('android_clear_text');
        if (args.getString('method') != 'type') return to('android_set_text');
        if (args.getOptionalInt('elementId') != null) {
          _invalid('elementId works with method "paste" only.');
        }
        return to('android_type_text');
      case 'android_press_key':
        final key = args.getRequiredString('key').toUpperCase();
        if (buttonKeys.contains(key)) {
          return to('android_press_button', {'button': key.toLowerCase()});
        }
        if (panelKeys[key] case final panel?) {
          return to('android_open_notification_panel', {
            'expand': panel.expand,
            'quickSettings': panel.quickSettings,
          });
        }
        return to('android_press_key', {'key': key});
      case 'android_get_ui_tree':
        return to(
          args.getString('format') == 'xml'
              ? 'android_dump_hierarchy'
              : 'android_get_semantic_tree',
        );
      case 'android_click_element':
        return to(
          args.getOptionalInt('id') != null
              ? 'android_click_element_by_id'
              : 'android_click_element',
        );
      case 'android_stop_app':
        return to(
          args.getOptionalInt('pid') != null
              ? 'android_kill_process'
              : 'android_stop_app',
        );
      case 'android_set_permission':
        if (args.getOptionalBool('grant') == null) {
          _invalid('Missing required parameter "grant" (true or false).');
        }
        return to(
          args.getBool('grant')
              ? 'android_grant_permission'
              : 'android_revoke_permission',
        );
      case 'android_get_device_stats':
        final kind = args.getRequiredString('kind');
        return to(
          statsOperations[kind] ??
              _invalid(
                'Unknown kind "$kind" (${statsOperations.keys.join(', ')}).',
              ),
        );
      case 'android_set_network':
        final mode = args.getRequiredString('mode');
        if (radioModes[mode] case (final name, final enable)) {
          return to(name, {'enable': enable});
        }
        return to('android_set_network_condition');
      case 'android_clipboard':
        return to(
          args.getOptionalText('text') != null
              ? 'android_set_clipboard'
              : 'android_get_clipboard',
        );
      case 'android_transfer_file':
        return switch (args.getRequiredString('direction')) {
          'push' => to('android_push_file'),
          'pull' => to('android_pull_file'),
          'scan' => to('android_scan_media_file', {
            'filePath': args.getRequiredString('remotePath'),
          }),
          final other => _invalid(
            'Unknown direction "$other" (push, pull, scan).',
          ),
        };
      case 'android_list_apps':
        return to(
          args.getBool('running')
              ? 'android_list_processes'
              : 'android_list_packages',
          {'filter': ?args.getString('query')},
        );
      case 'android_get_logcat':
        if (args.getBool('crashesOnly', aliases: ['crashes'])) {
          return to('android_check_crash');
        }
        final scoped =
            args.getString('package', aliases: ['pkg']) != null ||
            args.getOptionalInt('sinceSeconds') != null;
        return to(scoped ? 'android_get_app_logcat' : 'android_get_logcat');
      case 'android_launch_app':
        return to(
          args.getBool('measure')
              ? 'android_measure_app_start'
              : 'android_launch_app',
        );
      case 'android_wait_for_condition':
        return to(
          screenConditions.contains(args.getString('condition'))
              ? 'android_wait_for_screen'
              : 'android_wait_for_condition',
        );
      default:
        return to(tool);
    }
  }

  static Never _invalid(String message) => throw McpArgumentException(message);
}
