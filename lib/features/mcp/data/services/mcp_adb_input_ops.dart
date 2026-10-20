part of 'mcp_adb_client.dart';

/// Static operations for screen capture, touch gestures, and key injections.
class McpAdbInputOps {
  const McpAdbInputOps._();

  /// Captures raw PNG bytes from Android screencap.
  static Future<List<int>?> captureScreenshotBytes(
    McpAdbClient client,
    String serial,
  ) async {
    final adb = await client.resolveAdb();
    if (adb == null) return null;

    final res = await Process.run(adb, [
      '-s',
      serial,
      'exec-out',
      'screencap',
      '-p',
    ], stdoutEncoding: null);
    if (res.exitCode == 0 && res.stdout is List<int>) {
      return res.stdout as List<int>;
    }
    return null;
  }

  static final _sizeCache = <String, Point<int>>{};

  /// Queries the display's physical resolution, caching the result per serial.
  static Future<Point<int>> getDisplaySize(
    McpAdbClient client,
    String serial, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _sizeCache.containsKey(serial)) {
      return _sizeCache[serial]!;
    }
    final res = await client.run(['-s', serial, 'shell', 'wm', 'size']);
    final out = res.stdout.toString();
    final match = RegExp(r'Physical size:\s*(\d+)x(\d+)').firstMatch(out);
    if (match != null) {
      final w = int.parse(match.group(1)!);
      final h = int.parse(match.group(2)!);
      final size = Point(w, h);
      _sizeCache[serial] = size;
      return size;
    }
    return _sizeCache[serial] ?? const Point(1080, 2400);
  }

  /// Clears cached screen dimension for [serial] (e.g. after screen rotation).
  static void invalidateDisplaySize(String serial) => _sizeCache.remove(serial);

  /// Injects a touch tap gesture at pixel or normalized coordinates.
  static Future<bool> tap(
    McpAdbClient client,
    String serial,
    double x,
    double y,
  ) async {
    var targetX = x.round();
    var targetY = y.round();
    if (x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0) {
      final size = await getDisplaySize(client, serial);
      targetX = (x * size.x).round();
      targetY = (y * size.y).round();
    }
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'tap',
      '$targetX',
      '$targetY',
    ]);
    return res.exitCode == 0;
  }

  /// Injects a rapid double-tap gesture within the threshold (default 120ms).
  static Future<bool> doubleTap(
    McpAdbClient client,
    String serial,
    double x,
    double y, {
    int intervalMs = 120,
  }) async {
    int targetX = x.round();
    int targetY = y.round();
    if (x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0) {
      final size = await getDisplaySize(client, serial);
      targetX = (x * size.x).round();
      targetY = (y * size.y).round();
    }

    final sleepSec = (intervalMs / 1000.0).toStringAsFixed(3);
    final cmd =
        'input tap $targetX $targetY && sleep $sleepSec && input tap $targetX $targetY';
    final res = await client.run(['-s', serial, 'shell', cmd]);
    return res.exitCode == 0;
  }

  /// Injects a swipe gesture from start to end coordinates.
  static Future<bool> swipe(
    McpAdbClient client,
    String serial,
    double sx,
    double sy,
    double ex,
    double ey,
    int durationMs,
  ) async {
    int startX = sx.round();
    int startY = sy.round();
    int endX = ex.round();
    int endY = ey.round();
    if (sx >= 0.0 && sx <= 1.0) {
      final size = await getDisplaySize(client, serial);
      startX = (sx * size.x).round();
      startY = (sy * size.y).round();
      endX = (ex * size.x).round();
      endY = (ey * size.y).round();
    }
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'swipe',
      '$startX',
      '$startY',
      '$endX',
      '$endY',
      '$durationMs',
    ]);
    return res.exitCode == 0;
  }

  /// Injects a smooth, controlled drag gesture for seekbars, sliders, and list reordering.
  static Future<bool> drag(
    McpAdbClient client,
    String serial,
    double startX,
    double startY,
    double endX,
    double endY, {
    int durationMs = 1000,
  }) => swipe(client, serial, startX, startY, endX, endY, durationMs);

  /// Performs an inertial scroll or fling gesture in [direction] ('down', 'up', 'left', 'right')
  /// or between explicit normalized/pixel coordinates.
  static Future<bool> scroll(
    McpAdbClient client,
    String serial, {
    String direction = 'down',
    double distance = 0.6,
    String speed = 'normal',
    double? startX,
    double? startY,
    double? endX,
    double? endY,
    int? durationMs,
  }) async {
    int duration;
    if (durationMs != null && durationMs > 0) {
      duration = durationMs;
    } else {
      switch (speed.toLowerCase().trim()) {
        case 'fast' || 'fling':
          duration = 80;
        case 'slow' || 'drag':
          duration = 600;
        case 'normal':
        default:
          duration = 250;
      }
    }

    final dist = distance.clamp(0.05, 0.95);
    double sx;
    double sy;
    double ex;
    double ey;

    if (startX != null && startY != null && endX != null && endY != null) {
      sx = startX;
      sy = startY;
      ex = endX;
      ey = endY;
    } else {
      final dir = direction.toLowerCase().trim();
      switch (dir) {
        case 'up':
          // Swipe downwards to scroll view UP (reveal higher content)
          sx = 0.5;
          sy = (0.5 - dist / 2).clamp(0.05, 0.95);
          ex = 0.5;
          ey = (0.5 + dist / 2).clamp(0.05, 0.95);
        case 'left':
          // Swipe rightwards to scroll view LEFT (reveal content on the left)
          sx = (0.5 - dist / 2).clamp(0.05, 0.95);
          sy = 0.5;
          ex = (0.5 + dist / 2).clamp(0.05, 0.95);
          ey = 0.5;
        case 'right':
          // Swipe leftwards to scroll view RIGHT (reveal content on the right)
          sx = (0.5 + dist / 2).clamp(0.05, 0.95);
          sy = 0.5;
          ex = (0.5 - dist / 2).clamp(0.05, 0.95);
          ey = 0.5;
        case 'down':
        default:
          // Swipe upwards to scroll view DOWN (reveal lower content)
          sx = 0.5;
          sy = (0.5 + dist / 2).clamp(0.05, 0.95);
          ex = 0.5;
          ey = (0.5 - dist / 2).clamp(0.05, 0.95);
      }
    }

    return swipe(client, serial, sx, sy, ex, ey, duration);
  }
}
