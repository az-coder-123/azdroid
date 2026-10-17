part of 'mcp_adb_client.dart';

/// Implements Notification inspection/dismissal, Notification Panel toggles,
/// SharedPreferences reading, and Hardware Button simulation for ADB MCP operations.
class McpAdbNotificationButtonOps {
  const McpAdbNotificationButtonOps._();

  static Future<List<Map<String, String>>> getNotifications(
    McpAdbClient client,
    String serial, {
    String? filter,
  }) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys',
      'notification',
      '--noredact',
    ]);
    final notifications = <Map<String, String>>[];
    for (final block
        in (res.stdout?.toString() ?? '')
            .split(RegExp(r'NotificationRecord\('))
            .skip(1)) {
      final pkg =
          RegExp(r'pkg=([a-zA-Z0-9_\.]+)').firstMatch(block)?.group(1) ??
          'system';
      final title =
          RegExp(r'android\.title=([^\n]+)')
              .firstMatch(block)
              ?.group(1)
              ?.trim() ??
          '';
      final text =
          RegExp(r'android\.text=([^\n]+)')
              .firstMatch(block)
              ?.group(1)
              ?.trim() ??
          '';

      if (filter != null && filter.isNotEmpty) {
        final q = filter.toLowerCase();
        if (!pkg.toLowerCase().contains(q) &&
            !title.toLowerCase().contains(q) &&
            !text.toLowerCase().contains(q)) {
          continue;
        }
      }
      if (title.isNotEmpty || text.isNotEmpty) {
        notifications.add({'package': pkg, 'title': title, 'text': text});
      }
    }
    return notifications;
  }

  static Future<bool> dismissNotification(
    McpAdbClient client,
    String serial, {
    String? key,
    bool clearAll = false,
  }) async {
    final args = clearAll
        ? ['-s', serial, 'shell', 'service', 'call', 'statusbar', '1']
        : ['-s', serial, 'shell', 'cmd', 'notification', 'cancel', key ?? ''];
    final res = await client.run(args);
    return res.exitCode == 0;
  }

  static Future<bool> openNotificationPanel(
    McpAdbClient client,
    String serial, {
    bool expand = true,
    bool quickSettings = false,
  }) async {
    final cmd = !expand
        ? 'collapse'
        : (quickSettings ? 'expand-settings' : 'expand-notifications');
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'statusbar',
      cmd,
    ]);
    return res.exitCode == 0;
  }

  static Future<String> readSharedPreferences(
    McpAdbClient client,
    String serial, {
    required String package,
    String? fileName,
  }) async {
    final file = fileName ?? '${package}_preferences.xml';
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'run-as',
      package,
      'cat',
      'shared_prefs/$file',
    ]);
    if (res.exitCode == 0 && (res.stdout?.toString().isNotEmpty ?? false)) {
      return res.stdout.toString();
    }
    final fallback = await client.run([
      '-s',
      serial,
      'shell',
      'cat',
      '/data/data/$package/shared_prefs/$file',
    ]);
    return fallback.stdout?.toString() ??
        'Preference file not accessible (app not debuggable).';
  }

  static Future<bool> pressButton(
    McpAdbClient client,
    String serial,
    String button,
  ) async {
    const keyMap = <String, int>{
      'volume_up': 24,
      'volume_down': 25,
      'camera': 27,
      'mute': 164,
      'wakeup': 224,
      'sleep': 223,
      'media_play_pause': 85,
      'media_next': 87,
      'media_prev': 88,
    };
    final code = keyMap[button.toLowerCase()];
    return code != null ? client.pressKey(serial, code) : false;
  }
}
