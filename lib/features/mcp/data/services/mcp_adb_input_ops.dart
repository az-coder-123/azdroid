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

  /// [point] in pixels; queries the display size only when it holds a
  /// screen fraction. The one place coordinates are resolved (see [McpPoint]).
  static Future<(int, int)> toPixels(
    McpAdbClient client,
    String serial,
    McpPoint point,
  ) async {
    if (!point.needsDisplaySize) return point.toPixels(0, 0);
    final size = await getDisplaySize(client, serial);
    return point.toPixels(size.x, size.y);
  }

  /// Injects a touch tap gesture at [point].
  static Future<bool> tap(
    McpAdbClient client,
    String serial,
    McpPoint point,
  ) async {
    final (x, y) = await toPixels(client, serial, point);
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'tap',
      '$x',
      '$y',
    ]);
    return res.exitCode == 0;
  }

  /// Injects a touch tap gesture, then verifies whether the UI state changed.
  /// Captures hierarchy before and after tap with a configurable [delayMs] window.
  static Future<(bool ok, bool stateChanged)> tapAndVerify(
    McpAdbClient client,
    String serial,
    McpPoint point, {
    int delayMs = 300,
  }) async {
    final beforeXml = await McpAdbUiOps.dumpHierarchy(
      client,
      serial,
      compressed: true,
    );

    final ok = await tap(client, serial, point);
    if (!ok) return (false, false);

    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    final afterXml = await McpAdbUiOps.dumpHierarchy(
      client,
      serial,
      compressed: true,
    );

    if (beforeXml.startsWith('Error:') || afterXml.startsWith('Error:')) {
      return (true, false);
    }

    final stateChanged = beforeXml.trim() != afterXml.trim();
    return (true, stateChanged);
  }

  /// Injects a rapid double-tap gesture within the threshold (default 120ms).
  static Future<bool> doubleTap(
    McpAdbClient client,
    String serial,
    McpPoint point, {
    int intervalMs = 120,
  }) async {
    final (x, y) = await toPixels(client, serial, point);
    final sleepSec = (intervalMs / 1000.0).toStringAsFixed(3);
    final cmd = 'input tap $x $y && sleep $sleepSec && input tap $x $y';
    final res = await client.run(['-s', serial, 'shell', cmd]);
    return res.exitCode == 0;
  }

  /// Injects a swipe gesture from [start] to [end].
  static Future<bool> swipe(
    McpAdbClient client,
    String serial,
    McpPoint start,
    McpPoint end,
    int durationMs,
  ) async {
    final (startX, startY) = await toPixels(client, serial, start);
    final (endX, endY) = await toPixels(client, serial, end);
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
    McpPoint start,
    McpPoint end, {
    int durationMs = 1000,
  }) => swipe(client, serial, start, end, durationMs);

  /// Performs an inertial scroll or fling gesture in [direction] ('down', 'up',
  /// 'left', 'right'), or along [start]→[end] when both are given.
  static Future<bool> scroll(
    McpAdbClient client,
    String serial, {
    String direction = 'down',
    double distance = 0.6,
    String speed = 'normal',
    McpPoint? start,
    McpPoint? end,
    int? durationMs,
  }) {
    final duration = mcpScrollDurationMs(speed, durationMs);
    final path = start != null && end != null
        ? (start: start, end: end)
        : mcpScrollPath(direction, distance);
    return swipe(client, serial, path.start, path.end, duration);
  }
}
