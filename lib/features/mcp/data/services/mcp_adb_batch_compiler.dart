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

  /// Resolves pixel start, end, and duration for scroll gestures (the same
  /// path and timing as `android_scroll`).
  static (int, int, int, int, int) resolveScrollCoordinates(
    Map<String, dynamic> a,
    Point<int> size,
  ) {
    final distance = parseNum(a['distance'] ?? a['dist'])?.toDouble() ?? 0.6;
    final speed =
        (a['speed'] ??
                a['velocity'] ??
                (a['action'] == 'fling' ? 'fast' : 'normal'))
            .toString();
    final dur = mcpScrollDurationMs(
      speed,
      parseInt(a['durationMs'] ?? a['duration']),
    );
    final path = mcpScrollPath(
      (a['direction'] ?? a['dir'] ?? 'down').toString(),
      distance,
    );
    final (sx, sy) = path.start.toPixels(size.x, size.y);
    final (ex, ey) = path.end.toPixels(size.x, size.y);
    return (sx, sy, ex, ey, dur);
  }

  /// Resolves a pixel point with the same rules as every other tool
  /// ([McpPoint]); `(null, null)` when either axis is missing.
  static (int?, int?) resolvePoint(
    Map<String, dynamic> a,
    Point<int> size,
    String xKey,
    String yKey, {
    String? altX,
    String? altY,
  }) {
    final point = a.getOptionalPoint(
      xKey: xKey,
      yKey: yKey,
      xAliases: [?altX],
      yAliases: [?altY],
    );
    return point == null ? (null, null) : point.toPixels(size.x, size.y);
  }

  static num? parseNum(dynamic v) =>
      v == null ? null : (v is num ? v : num.tryParse(v.toString().trim()));

  static int? parseInt(dynamic v) => v == null
      ? null
      : (v is int
            ? v
            : (v is num ? v.toInt() : int.tryParse(v.toString().trim())));
}
