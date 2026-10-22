import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_router.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String op(String tool, [Map<String, dynamic> args = const {}]) =>
      McpToolRouter.route(tool, args).name;
  Map<String, dynamic> argsOf(String tool, Map<String, dynamic> args) =>
      McpToolRouter.route(tool, args).arguments;

  test('tap: single, double, and hold', () {
    expect(op('android_tap', {'x': 1, 'y': 1}), 'android_tap');
    expect(op('android_tap', {'taps': 2}), 'android_double_tap');
    expect(op('android_tap', {'holdMs': 800}), 'android_long_press');
    expect(argsOf('android_tap', {'holdMs': 800})['durationMs'], 800);
    expect(
      () => op('android_tap', {'taps': 2, 'holdMs': 800}),
      throwsA(isA<McpArgumentException>()),
    );
  });

  test('swipe: fling, drag, and directional scroll', () {
    expect(op('android_swipe', {}), 'android_swipe');
    expect(op('android_swipe', {'style': 'drag'}), 'android_drag');
    expect(op('android_swipe', {'direction': 'down'}), 'android_scroll');
  });

  test('text: paste, type, clear', () {
    expect(op('android_input_text', {'text': 'Xin chào'}), 'android_set_text');
    expect(
      op('android_input_text', {'text': 'abc', 'method': 'type'}),
      'android_type_text',
    );
    expect(op('android_input_text', {'text': ''}), 'android_clear_text');
    expect(
      () => op('android_input_text', {
        'text': 'abc',
        'method': 'type',
        'elementId': 3,
      }),
      throwsA(isA<McpArgumentException>()),
    );
  });

  test('text keeps its spaces: a space is typed, not a clear', () {
    expect(op('android_input_text', {'text': ' '}), 'android_set_text');
    expect(argsOf('android_input_text', {'text': 'Hello '})['text'], 'Hello ');
    expect(op('android_clipboard', {'text': ' '}), 'android_set_clipboard');
  });

  test('getText keeps spaces; getString trims', () {
    final args = {'text': ' a b '};
    expect(args.getText('text'), ' a b ');
    expect(args.getString('text'), 'a b');
    expect(
      () => {'text': ''}.getText('text'),
      throwsA(isA<McpArgumentException>()),
    );
  });

  test('press_key: keys, buttons, and panels', () {
    expect(op('android_press_key', {'key': 'back'}), 'android_press_key');
    expect(argsOf('android_press_key', {'key': 'back'})['key'], 'BACK');
    final wake = argsOf('android_press_key', {'key': 'WAKEUP'});
    expect(op('android_press_key', {'key': 'WAKEUP'}), 'android_press_button');
    expect(wake['button'], 'wakeup');
    final qs = argsOf('android_press_key', {'key': 'QUICK_SETTINGS'});
    expect(qs['expand'], isTrue);
    expect(qs['quickSettings'], isTrue);
    expect(
      argsOf('android_press_key', {'key': 'CLOSE_PANELS'})['expand'],
      isFalse,
    );
  });

  test('ui, apps, and permissions', () {
    expect(op('android_get_ui_tree'), 'android_get_semantic_tree');
    expect(
      op('android_get_ui_tree', {'format': 'xml'}),
      'android_dump_hierarchy',
    );
    expect(
      op('android_click_element', {'id': 4}),
      'android_click_element_by_id',
    );
    expect(
      op('android_click_element', {'text': 'OK'}),
      'android_click_element',
    );
    expect(op('android_stop_app', {'pid': 99}), 'android_kill_process');
    expect(op('android_stop_app', {'package': 'a.b'}), 'android_stop_app');
    expect(
      op('android_set_permission', {'grant': true}),
      'android_grant_permission',
    );
    expect(
      op('android_set_permission', {'grant': false}),
      'android_revoke_permission',
    );
    expect(
      () => op('android_set_permission', {'package': 'a.b'}),
      throwsA(isA<McpArgumentException>()),
    );
    expect(op('android_list_apps'), 'android_list_packages');
    expect(
      op('android_list_apps', {'running': true}),
      'android_list_processes',
    );
    expect(
      argsOf('android_list_apps', {
        'running': true,
        'query': 'chrome',
      })['filter'],
      'chrome',
    );
  });

  test('device data, network, clipboard, files, logs', () {
    expect(
      op('android_get_device_stats', {'kind': 'gfx'}),
      'android_get_gfx_info',
    );
    expect(
      () => op('android_get_device_stats', {'kind': 'disk'}),
      throwsA(isA<McpArgumentException>()),
    );
    expect(
      op('android_set_network', {'mode': 'offline'}),
      'android_set_network_condition',
    );
    final wifiOff = McpToolRouter.route('android_set_network', {
      'mode': 'wifi_off',
    });
    expect(wifiOff.name, 'android_toggle_wifi');
    expect(wifiOff.arguments['enable'], isFalse);
    expect(
      op('android_set_network', {'mode': 'airplane_on'}),
      'android_toggle_airplane_mode',
    );
    expect(op('android_clipboard'), 'android_get_clipboard');
    expect(op('android_clipboard', {'text': 'x'}), 'android_set_clipboard');
    expect(
      op('android_transfer_file', {'direction': 'pull'}),
      'android_pull_file',
    );
    expect(
      argsOf('android_transfer_file', {
        'direction': 'scan',
        'remotePath': '/sdcard/a.mp3',
      })['filePath'],
      '/sdcard/a.mp3',
    );
    expect(
      op('android_get_logcat', {'crashesOnly': true}),
      'android_check_crash',
    );
    expect(op('android_get_logcat'), 'android_get_logcat');
  });

  test('development branches: app logs, launch timing, fps, screen waits', () {
    expect(
      op('android_get_logcat', {'package': 'a.b'}),
      'android_get_app_logcat',
    );
    expect(
      op('android_get_logcat', {'sinceSeconds': 30}),
      'android_get_app_logcat',
    );
    expect(
      op('android_get_logcat', {'package': 'a.b', 'crashesOnly': true}),
      'android_check_crash',
    );
    expect(op('android_launch_app', {'package': 'a.b'}), 'android_launch_app');
    expect(
      op('android_launch_app', {'package': 'a.b', 'measure': true}),
      'android_measure_app_start',
    );
    expect(
      op('android_get_device_stats', {'kind': 'fps'}),
      'android_get_frame_rate',
    );
    expect(
      op('android_get_device_stats', {'kind': 'thermal'}),
      'android_get_thermal',
    );
    for (final c in ['image_present', 'screen_changed']) {
      expect(
        op('android_wait_for_condition', {'condition': c}),
        'android_wait_for_screen',
      );
    }
    expect(
      op('android_wait_for_condition', {'condition': 'element_present'}),
      'android_wait_for_condition',
    );
  });

  test('older names and unchanged tools pass through untouched', () {
    for (final name in [
      'android_double_tap',
      'android_set_text',
      'android_toggle_wifi',
      'android_take_screenshot',
    ]) {
      expect(op(name, {'x': 1}), name);
    }
  });
}
