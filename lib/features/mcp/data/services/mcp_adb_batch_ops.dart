part of 'mcp_adb_client.dart';

/// Implements high-speed Compound Macro & Batch Actions execution for ADB MCP.
class McpAdbBatchOps {
  const McpAdbBatchOps._();

  static Future<List<Map<String, dynamic>>> batchActions(
    McpAdbClient client,
    String serial,
    List<Map<String, dynamic>> actions,
  ) async {
    if (actions.isEmpty) return const [];

    final size = await McpAdbInputOps.getDisplaySize(client, serial);
    final commands = <int, String>{};
    for (var i = 0; i < actions.length; i++) {
      final cmd = _compileShellAction(actions[i], size);
      if (cmd != null) commands[i] = cmd;
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
            final (x, y) = _resolvePoint(
              a,
              size,
              'x',
              'y',
              altX: 'xCoord',
              altY: 'yCoord',
            );
            if (x == null || y == null) {
              results.add({'step': i, 'error': 'Missing coordinates'});
              continue;
            }
            final ok = await client.tap(serial, x.toDouble(), y.toDouble());
            results.add({'step': i, 'action': 'tap', 'success': ok});
          case 'type':
            final text = (a['text'] ?? a['input'] ?? '').toString();
            final ok = await client.typeText(serial, text);
            results.add({'step': i, 'action': 'type', 'success': ok});
          case 'key':
            final code = _parseInt(a['keyCode'] ?? a['key'] ?? a['code']) ?? 0;
            final ok = await client.pressKey(serial, code);
            results.add({'step': i, 'action': 'key', 'success': ok});
          case 'swipe':
            final (x1, y1) = _resolvePoint(
              a,
              size,
              'startX',
              'startY',
              altX: 'x1',
              altY: 'y1',
            );
            final (x2, y2) = _resolvePoint(
              a,
              size,
              'endX',
              'endY',
              altX: 'x2',
              altY: 'y2',
            );
            if (x1 == null || y1 == null || x2 == null || y2 == null) {
              results.add({'step': i, 'error': 'Missing coordinates'});
              continue;
            }
            final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 300;
            final ok = await client.swipe(
              serial,
              x1.toDouble(),
              y1.toDouble(),
              x2.toDouble(),
              y2.toDouble(),
              dur,
            );
            results.add({'step': i, 'action': 'swipe', 'success': ok});
          case 'sleep':
            final ms =
                _parseInt(a['durationMs'] ?? a['duration'] ?? a['timeMs']) ??
                500;
            await Future<void>.delayed(Duration(milliseconds: ms));
            results.add({'step': i, 'action': 'sleep', 'success': true});
          case 'double_tap' || 'doubletap':
            final (x, y) = _resolvePoint(
              a,
              size,
              'x',
              'y',
              altX: 'xCoord',
              altY: 'yCoord',
            );
            if (x == null || y == null) {
              results.add({'step': i, 'error': 'Missing coordinates'});
              continue;
            }
            final interval = _parseInt(a['intervalMs']) ?? 120;
            final ok = await client.doubleTap(
              serial,
              x.toDouble(),
              y.toDouble(),
              intervalMs: interval,
            );
            results.add({'step': i, 'action': 'double_tap', 'success': ok});
          case 'pinch':
            final scale =
                _parseNum(a['scale'] ?? a['scaleFactor'] ?? a['zoom'])
                    ?.toDouble() ??
                1.5;
            final (cx, cy) = _resolvePoint(
              a,
              size,
              'centerX',
              'centerY',
              altX: 'x',
              altY: 'y',
            );
            final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 400;
            final ok = await client.pinchGesture(
              serial,
              scale: scale,
              centerX: cx != null ? cx / size.x : 0.5,
              centerY: cy != null ? cy / size.y : 0.5,
              durationMs: dur,
            );
            results.add({'step': i, 'action': 'pinch', 'success': ok});
          case 'rotate':
            final angle =
                _parseNum(a['angleDegrees'] ?? a['angle'] ?? a['degrees'])
                    ?.toDouble() ??
                90.0;
            final (cx, cy) = _resolvePoint(
              a,
              size,
              'centerX',
              'centerY',
              altX: 'x',
              altY: 'y',
            );
            final r = _parseNum(a['radius'] ?? a['r'])?.toDouble() ?? 200.0;
            final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 400;
            final ok = await client.rotateGesture(
              serial,
              angleDegrees: angle,
              centerX: cx != null ? cx / size.x : 0.5,
              centerY: cy != null ? cy / size.y : 0.5,
              radius: r,
              durationMs: dur,
            );
            results.add({'step': i, 'action': 'rotate', 'success': ok});
          default:
            results.add({'step': i, 'error': 'Unknown action: $type'});
        }
      } catch (e) {
        results.add({'step': i, 'action': type, 'error': e.toString()});
      }
    }
    return results;
  }

  static String? _compileShellAction(Map<String, dynamic> a, Point<int> size) {
    final type = a['action']?.toString().toLowerCase().trim();
    switch (type) {
      case 'tap':
        final (x, y) = _resolvePoint(
          a,
          size,
          'x',
          'y',
          altX: 'xCoord',
          altY: 'yCoord',
        );
        if (x == null || y == null) return null;
        return 'input tap $x $y';
      case 'double_tap' || 'doubletap':
        final (x, y) = _resolvePoint(
          a,
          size,
          'x',
          'y',
          altX: 'xCoord',
          altY: 'yCoord',
        );
        if (x == null || y == null) return null;
        final interval = _parseInt(a['intervalMs']) ?? 120;
        final sec = (interval / 1000.0).toStringAsFixed(3);
        return 'input tap $x $y && sleep $sec && input tap $x $y';
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
        final (x1, y1) = _resolvePoint(
          a,
          size,
          'startX',
          'startY',
          altX: 'x1',
          altY: 'y1',
        );
        final (x2, y2) = _resolvePoint(
          a,
          size,
          'endX',
          'endY',
          altX: 'x2',
          altY: 'y2',
        );
        if (x1 == null || y1 == null || x2 == null || y2 == null) return null;
        final dur = _parseInt(a['durationMs'] ?? a['duration']) ?? 300;
        return 'input swipe $x1 $y1 $x2 $y2 $dur';
      case 'sleep':
        final ms =
            _parseInt(a['durationMs'] ?? a['duration'] ?? a['timeMs']) ?? 500;
        return 'sleep ${(ms / 1000.0).toStringAsFixed(2)}';
      default:
        return null;
    }
  }

  static (int?, int?) _resolvePoint(
    Map<String, dynamic> a,
    Point<int> size,
    String xKey,
    String yKey, {
    String? altX,
    String? altY,
  }) {
    final xr = _parseNum(a['${xKey}Ratio'] ?? a['${xKey}Percent']);
    final yr = _parseNum(a['${yKey}Ratio'] ?? a['${yKey}Percent']);
    if (xr != null && yr != null) {
      return ((xr * size.x).round(), (yr * size.y).round());
    }
    final rx = _parseNum(a[xKey] ?? (altX != null ? a[altX] : null));
    final ry = _parseNum(a[yKey] ?? (altY != null ? a[altY] : null));
    if (rx == null || ry == null) return (null, null);
    if (rx > 0.0 && rx < 1.0 && ry > 0.0 && ry < 1.0) {
      return ((rx * size.x).round(), ((ry * size.y).round()));
    }
    return (rx.round(), ry.round());
  }

  static num? _parseNum(dynamic v) =>
      v == null ? null : (v is num ? v : num.tryParse(v.toString().trim()));

  static int? _parseInt(dynamic v) => v == null
      ? null
      : (v is int
            ? v
            : (v is num ? v.toInt() : int.tryParse(v.toString().trim())));
}
