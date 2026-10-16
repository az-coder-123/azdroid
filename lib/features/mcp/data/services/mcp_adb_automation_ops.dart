part of 'mcp_adb_client.dart';

/// Implements Smart Waiting, Batch Actions, Notifications, Mock Location,
/// Network Conditioning, and Button events for ADB MCP operations.
class McpAdbAutomationOps {
  const McpAdbAutomationOps._();

  static Future<Map<String, dynamic>?> waitForElement(
    McpAdbClient client,
    String serial, {
    String? text,
    String? resourceId,
    String? contentDesc,
    int timeoutMs = 10000,
    int pollIntervalMs = 500,
  }) async {
    final start = DateTime.now();
    final end = start.add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(end)) {
      final found = await McpAdbUiOps.findElement(
        client,
        serial,
        text: text,
        resourceId: resourceId,
        contentDesc: contentDesc,
      );
      if (found != null) {
        return {
          ...found,
          'elapsedMs': DateTime.now().difference(start).inMilliseconds,
        };
      }
      await Future<void>.delayed(Duration(milliseconds: pollIntervalMs));
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> batchActions(
    McpAdbClient client,
    String serial,
    List<Map<String, dynamic>> actions,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < actions.length; i++) {
      final a = actions[i];
      final type = a['action']?.toString().toLowerCase();
      try {
        switch (type) {
          case 'tap':
            final success = await client.tap(
              serial,
              (a['x'] as num).toDouble(),
              (a['y'] as num).toDouble(),
            );
            results.add({'step': i, 'action': 'tap', 'success': success});
          case 'type':
            final success = await client.typeText(
              serial,
              a['text']?.toString() ?? '',
            );
            results.add({'step': i, 'action': 'type', 'success': success});
          case 'key':
            final code = a['keyCode'] is int
                ? a['keyCode'] as int
                : int.tryParse(a['keyCode']?.toString() ?? '0') ?? 0;
            final success = await client.pressKey(serial, code);
            results.add({'step': i, 'action': 'key', 'success': success});
          case 'swipe':
            final success = await client.swipe(
              serial,
              (a['startX'] as num).toDouble(),
              (a['startY'] as num).toDouble(),
              (a['endX'] as num).toDouble(),
              (a['endY'] as num).toDouble(),
              (a['durationMs'] as int?) ?? 300,
            );
            results.add({'step': i, 'action': 'swipe', 'success': success});
          case 'sleep':
            await Future<void>.delayed(
              Duration(milliseconds: (a['durationMs'] as int?) ?? 500),
            );
            results.add({'step': i, 'action': 'sleep', 'success': true});
          default:
            results.add({'step': i, 'error': 'Unknown action: $type'});
        }
      } catch (e) {
        results.add({'step': i, 'action': type, 'error': e.toString()});
      }
    }
    return results;
  }

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

  static Future<bool> setLocation(
    McpAdbClient client,
    String serial, {
    required double latitude,
    required double longitude,
    double? altitude,
  }) async {
    await client.run([
      '-s',
      serial,
      'shell',
      'settings',
      'put',
      'secure',
      'location_mode',
      '3',
    ]);
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'cmd',
      'location',
      'set-location',
      latitude.toString(),
      longitude.toString(),
      if (altitude != null) altitude.toString(),
    ]);
    if (res.exitCode == 0) return true;
    final emu = await client.run([
      '-s',
      serial,
      'emu',
      'geo',
      'fix',
      longitude.toString(),
      latitude.toString(),
    ]);
    return emu.exitCode == 0;
  }

  static Future<bool> setNetworkCondition(
    McpAdbClient client,
    String serial,
    String mode,
  ) async {
    switch (mode.toLowerCase()) {
      case 'offline':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'disable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'disable']);
      case 'wifi_only':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'enable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'disable']);
      case 'data_only':
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'disable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'enable']);
      default:
        await client.run(['-s', serial, 'shell', 'svc', 'wifi', 'enable']);
        await client.run(['-s', serial, 'shell', 'svc', 'data', 'enable']);
    }
    return true;
  }

  static Future<bool> longPress(
    McpAdbClient client,
    String serial,
    double x,
    double y, {
    int durationMs = 1000,
  }) => client.swipe(serial, x, y, x, y, durationMs);

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
