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
