part of 'mcp_adb_client.dart';

/// Helper to compile macro batch actions into single-shot ADB shell scripts.
class McpAdbBatchCompiler {
  const McpAdbBatchCompiler._();

  /// Compiles a single macro action into an adb shell command string, or null if uncompilable.
  static String? compile(Map<String, dynamic> a, Point<int> size) {
    final type = a['action']?.toString().toLowerCase().trim();
    switch (type) {
      case 'tap':
        final (x, y) = resolvePoint(
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
        final (x, y) = resolvePoint(
          a,
          size,
          'x',
          'y',
          altX: 'xCoord',
          altY: 'yCoord',
        );
        if (x == null || y == null) return null;
        final interval = parseInt(a['intervalMs']) ?? 120;
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
        final code = parseInt(a['keyCode'] ?? a['key'] ?? a['code']) ?? 0;
        return 'input keyevent $code';
      case 'swipe':
        final (x1, y1) = resolvePoint(
          a,
          size,
          'startX',
          'startY',
          altX: 'x1',
          altY: 'y1',
        );
        final (x2, y2) = resolvePoint(
          a,
          size,
          'endX',
          'endY',
          altX: 'x2',
          altY: 'y2',
        );
        if (x1 == null || y1 == null || x2 == null || y2 == null) return null;
        final dur = parseInt(a['durationMs'] ?? a['duration']) ?? 300;
        return 'input swipe $x1 $y1 $x2 $y2 $dur';
      case 'scroll' || 'fling':
        return compileScroll(a, size);
      case 'sleep':
        final ms =
            parseInt(a['durationMs'] ?? a['duration'] ?? a['timeMs']) ?? 500;
        return 'sleep ${(ms / 1000.0).toStringAsFixed(2)}';
      default:
        return null;
    }
  }

  /// Compiles a scroll or fling action into an input swipe command.
  static String? compileScroll(Map<String, dynamic> a, Point<int> size) {
    final (sx, sy, ex, ey, dur) = resolveScrollCoordinates(a, size);
    return 'input swipe $sx $sy $ex $ey $dur';
  }

  /// Resolves pixel start, end, and duration for scroll gestures.
  static (int, int, int, int, int) resolveScrollCoordinates(
    Map<String, dynamic> a,
    Point<int> size,
  ) {
    final dist = (parseNum(a['distance'] ?? a['dist'])?.toDouble() ?? 0.6)
        .clamp(0.05, 0.95);
    final speed =
        (a['speed'] ??
                a['velocity'] ??
                (a['action'] == 'fling' ? 'fast' : 'normal'))
            .toString()
            .toLowerCase()
            .trim();
    final durOverride = parseInt(a['durationMs'] ?? a['duration']);
    final dur =
        durOverride ??
        (speed == 'fast' || speed == 'fling'
            ? 80
            : (speed == 'slow' ? 600 : 250));

    final dir = (a['direction'] ?? a['dir'] ?? 'down')
        .toString()
        .toLowerCase()
        .trim();
    double sx = 0.5, sy = 0.5, ex = 0.5, ey = 0.5;
    switch (dir) {
      case 'up':
        sy = 0.5 - dist / 2;
        ey = 0.5 + dist / 2;
      case 'left':
        sx = 0.5 - dist / 2;
        ex = 0.5 + dist / 2;
      case 'right':
        sx = 0.5 + dist / 2;
        ex = 0.5 - dist / 2;
      case 'down':
      default:
        sy = 0.5 + dist / 2;
        ey = 0.5 - dist / 2;
    }
    return (
      (sx * size.x).round(),
      (sy * size.y).round(),
      (ex * size.x).round(),
      (ey * size.y).round(),
      dur,
    );
  }

  /// Resolves pixel point from normalized ratio or absolute pixels.
  static (int?, int?) resolvePoint(
    Map<String, dynamic> a,
    Point<int> size,
    String xKey,
    String yKey, {
    String? altX,
    String? altY,
  }) {
    final xr = parseNum(a['${xKey}Ratio'] ?? a['${xKey}Percent']);
    final yr = parseNum(a['${yKey}Ratio'] ?? a['${yKey}Percent']);
    if (xr != null && yr != null) {
      return ((xr * size.x).round(), (yr * size.y).round());
    }
    final rx = parseNum(a[xKey] ?? (altX != null ? a[altX] : null));
    final ry = parseNum(a[yKey] ?? (altY != null ? a[altY] : null));
    if (rx == null || ry == null) return (null, null);
    if (rx > 0.0 && rx < 1.0 && ry > 0.0 && ry < 1.0) {
      return ((rx * size.x).round(), ((ry * size.y).round()));
    }
    return (rx.round(), ry.round());
  }

  static num? parseNum(dynamic v) =>
      v == null ? null : (v is num ? v : num.tryParse(v.toString().trim()));

  static int? parseInt(dynamic v) => v == null
      ? null
      : (v is int
            ? v
            : (v is num ? v.toInt() : int.tryParse(v.toString().trim())));
}
