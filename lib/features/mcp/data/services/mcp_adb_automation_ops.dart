part of 'mcp_adb_client.dart';

/// Implements Smart Waiting, Batch Actions, Mock Location,
/// Network Conditioning, and Long Press gestures for ADB MCP operations.
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
    if (actions.isEmpty) return const [];

    // Attempt fast compound shell execution
    final commands = <int, String>{};
    for (var i = 0; i < actions.length; i++) {
      final cmd = _compileShellAction(actions[i]);
      if (cmd != null) {
        commands[i] = cmd;
      }
    }

    // When all actions are shell commands, execute them in a single compound ADB shell call
    if (commands.length == actions.length) {
      final parts = <String>[];
      for (var i = 0; i < actions.length; i++) {
        final cmd = commands[i]!;
        parts.add('$cmd && echo "DD_STEP:$i:OK" || echo "DD_STEP:$i:FAIL"');
      }
      final script = parts.join('; ');
      final res = await client.run(['-s', serial, 'shell', script]);
      final output = res.stdout.toString();

      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < actions.length; i++) {
        final actionType = actions[i]['action']?.toString() ?? 'unknown';
        final success = output.contains('DD_STEP:$i:OK');
        results.add({
          'step': i,
          'action': actionType,
          'success': success,
          if (!success) 'error': 'Command failed in compound execution',
        });
      }
      return results;
    }

    // Fallback: step-by-step execution for mixed or uncompiled commands
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < actions.length; i++) {
      final a = actions[i];
      final type = a['action']?.toString().toLowerCase().trim();
      try {
        switch (type) {
          case 'tap':
            final x = _parseNum(a['x'] ?? a['xCoord'])?.toDouble();
            final y = _parseNum(a['y'] ?? a['yCoord'])?.toDouble();
            if (x == null || y == null) {
              results.add({'step': i, 'error': 'Missing coordinates'});
              continue;
            }
            final success = await client.tap(serial, x, y);
            results.add({'step': i, 'action': 'tap', 'success': success});
          case 'type':
            final text = (a['text'] ?? a['input'] ?? '').toString();
            final success = await client.typeText(serial, text);
            results.add({'step': i, 'action': 'type', 'success': success});
          case 'key':
            final code = _parseInt(a['keyCode'] ?? a['key'] ?? a['code']) ?? 0;
            final success = await client.pressKey(serial, code);
            results.add({'step': i, 'action': 'key', 'success': success});
          case 'swipe':
            final x1 = _parseNum(a['startX'] ?? a['x1'])?.toDouble() ?? 0;
            final y1 = _parseNum(a['startY'] ?? a['y1'])?.toDouble() ?? 0;
            final x2 = _parseNum(a['endX'] ?? a['x2'])?.toDouble() ?? 0;
            final y2 = _parseNum(a['endY'] ?? a['y2'])?.toDouble() ?? 0;
            final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 300;
            final success = await client.swipe(serial, x1, y1, x2, y2, dur);
            results.add({'step': i, 'action': 'swipe', 'success': success});
          case 'sleep':
            final ms =
                _parseInt(a['durationMs'] ?? a['duration'] ?? a['timeMs']) ??
                500;
            await Future<void>.delayed(Duration(milliseconds: ms));
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

  static String? _compileShellAction(Map<String, dynamic> a) {
    final type = a['action']?.toString().toLowerCase().trim();
    switch (type) {
      case 'tap':
        final x = _parseNum(a['x'] ?? a['xCoord'])?.round();
        final y = _parseNum(a['y'] ?? a['yCoord'])?.round();
        if (x == null || y == null) return null;
        return 'input tap $x $y';
      case 'type':
        final text = (a['text'] ?? a['input'] ?? '').toString();
        final escaped = text
            .replaceAll(r'\', r'\\')
            .replaceAll('"', r'\"')
            .replaceAll(r'$', r'\$')
            .replaceAll('`', r'\`');
        return 'input text "$escaped"';
      case 'key':
        final code = _parseInt(a['keyCode'] ?? a['key'] ?? a['code']) ?? 0;
        return 'input keyevent $code';
      case 'swipe':
        final x1 = _parseNum(a['startX'] ?? a['x1'])?.round();
        final y1 = _parseNum(a['startY'] ?? a['y1'])?.round();
        final x2 = _parseNum(a['endX'] ?? a['x2'])?.round();
        final y2 = _parseNum(a['endY'] ?? a['y2'])?.round();
        if (x1 == null || y1 == null || x2 == null || y2 == null) return null;
        final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 300;
        return 'input swipe $x1 $y1 $x2 $y2 $dur';
      case 'sleep':
        final ms =
            _parseInt(a['durationMs'] ?? a['duration'] ?? a['timeMs']) ?? 500;
        final sec = (ms / 1000.0).toStringAsFixed(2);
        return 'sleep $sec';
      default:
        return null;
    }
  }

  static num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().trim());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
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
}
