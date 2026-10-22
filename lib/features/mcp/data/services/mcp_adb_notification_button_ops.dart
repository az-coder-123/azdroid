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
          _unwrapCharSequence(
            RegExp(r'android\.title=([^\n]+)')
                .firstMatch(block)
                ?.group(1)
                ?.trim(),
          ) ??
          '';
      final text =
          _unwrapCharSequence(
            RegExp(r'android\.text=([^\n]+)')
                .firstMatch(block)
                ?.group(1)
                ?.trim(),
          ) ??
          '';

      if (filter != null && filter.isNotEmpty) {
        final q = filter.toLowerCase();
        if (!pkg.toLowerCase().contains(q) &&
            !title.toLowerCase().contains(q) &&
            !text.toLowerCase().contains(q)) {
          continue;
        }
      }
      final key =
          RegExp(
            r'^\s*key=(\S+)\s*$',
            multiLine: true,
          ).firstMatch(block)?.group(1) ??
          '';
      if (title.isNotEmpty || text.isNotEmpty) {
        notifications.add({
          'package': pkg,
          'title': title,
          'text': text,
          'key': key,
        });
      }
    }
    return notifications;
  }

  /// Android 11+ prints extras as `String (text)` or `SpannableString
  /// (text)`; keeps only the text.
  static String? _unwrapCharSequence(String? value) {
    if (value == null) return null;
    final prefix = RegExp(r'^\w*String \(').firstMatch(value);
    if (prefix == null) return value;
    final inner = value.substring(prefix.end);
    // Multi-line text: only its first line is captured, without the ')'.
    return inner.endsWith(')') ? inner.substring(0, inner.length - 1) : inner;
  }

  /// Hides the notification [key] for [hideFor] by snoozing it, the only
  /// way adb can remove another app's notification (`cmd notification
  /// snooze`, Android 11+; missing on Android 10). It reappears afterwards.
  static Future<bool> snoozeNotification(
    McpAdbClient client,
    String serial, {
    required String key,
    required Duration hideFor,
  }) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'notification',
      'snooze',
      '--for',
      '${hideFor.inMilliseconds}',
      // Keys contain '|', which the device shell would read as a pipe.
      McpAdbTextOps.shellQuote(key),
    ]);
    if (res.isMissingCommand || _isUsageError(res)) {
      throw const McpUnsupportedOnDeviceException(
        'This device cannot snooze notifications over adb (`cmd '
        'notification snooze` needs Android 11 or later).',
      );
    }
    return res.succeeded;
  }

  /// `cmd notification` prints its usage instead of failing for an unknown
  /// subcommand on some versions.
  static bool _isUsageError(ProcessResult res) =>
      res.stdout.toString().contains('usage: cmd notification');

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
