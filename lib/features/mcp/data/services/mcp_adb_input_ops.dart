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

  static final _sizeCache = <String, (Point<int>, DateTime)>{};

  /// How long a display size is reused: long enough for a burst of calls,
  /// short enough to follow a rotation.
  static const Duration sizeCacheTtl = Duration(seconds: 3);

  /// The display size in the current orientation, including a `wm size`
  /// override: `cur=WxH` of `dumpsys window displays` (1600x720 in
  /// landscape on a 720x1600 phone, Android 10 and 13). Falls back to the
  /// physical size of `wm size`.
  static Future<Point<int>> getDisplaySize(
    McpAdbClient client,
    String serial, {
    bool forceRefresh = false,
  }) async {
    final cached = _sizeCache[serial];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.$2) < sizeCacheTtl) {
      return cached.$1;
    }
    final displays = await client.run([
      '-s',
      serial,
      'shell',
      'dumpsys window displays',
    ]);
    var match = RegExp(r'cur=(\d+)x(\d+)')
        .firstMatch(displays.stdout.toString());
    if (match == null) {
      final res = await client.run(['-s', serial, 'shell', 'wm', 'size']);
      match = RegExp(r'Physical size:\s*(\d+)x(\d+)')
          .firstMatch(res.stdout.toString());
    }
    if (match == null) return cached?.$1 ?? const Point(1080, 2400);
    final size = Point(int.parse(match.group(1)!), int.parse(match.group(2)!));
    _sizeCache[serial] = (size, DateTime.now());
    return size;
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

  /// Injects a touch tap gesture at [point]: through the scrcpy touch
  /// session when it runs ([McpFastInput]), otherwise `input tap`.
  static Future<bool> tap(
    McpAdbClient client,
    String serial,
    McpPoint point,
  ) async {
    final (x, y) = await toPixels(client, serial, point);
    if (await McpFastInput.play(client, serial, [McpFastInput.tap(x, y)])) {
      return true;
    }
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
    final hold = min(McpFastInput.tapHoldMs, intervalMs ~/ 2);
    if (await McpFastInput.play(client, serial, [
      McpFastInput.tap(x, y, holdMs: hold),
      McpFastInput.tap(x, y, atMs: intervalMs, holdMs: hold),
    ])) {
      return true;
    }
    final sleepSec = (intervalMs / 1000.0).toStringAsFixed(3);
    final cmd = 'input tap $x $y && sleep $sleepSec && input tap $x $y';
    final res = await client.run(['-s', serial, 'shell', cmd]);
    return res.exitCode == 0;
  }

  /// Injects a swipe gesture from [start] to [end] (scrcpy session first,
  /// then `input swipe`). Drags, scrolls, and long presses use it too.
  static Future<bool> swipe(
    McpAdbClient client,
    String serial,
    McpPoint start,
    McpPoint end,
    int durationMs,
  ) async {
    final (startX, startY) = await toPixels(client, serial, start);
    final (endX, endY) = await toPixels(client, serial, end);
    if (await McpFastInput.play(client, serial, [
      McpFastInput.swipe((startX, startY), (endX, endY), durationMs),
    ])) {
      return true;
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
