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

  /// Injects a multi-touch pinch gesture (zoom in or zoom out).
  /// Uses ScrcpyControlDatasource stream when mirroring is active,
  /// falling back to Android's universal 1-finger double-tap-and-drag zoom.
  static Future<bool> pinchGesture(
    McpAdbClient client,
    String serial, {
    required double scale,
    double centerX = 0.5,
    double centerY = 0.5,
    int durationMs = 400,
  }) async {
    final size = await getDisplaySize(client, serial);
    final cx = centerX <= 1.0 ? centerX * size.x : centerX;
    final cy = centerY <= 1.0 ? centerY * size.y : centerY;

    if (GetIt.I.isRegistered<ControlDatasource>()) {
      final ds = GetIt.I<ControlDatasource>();
      if (ds is ScrcpyControlDatasource && ds.isAvailableFor(serial)) {
        return _streamPinch(ds, serial, scale, cx, cy, size, durationMs);
      }
    }

    // Pure ADB fallback: Android universal double-tap-drag zoom gesture
    final distance = (size.y * 0.25).round();
    final startY = cy.round();
    final endY = scale >= 1.0
        ? (cy + distance).round().clamp(0, size.y)
        : (cy - distance).round().clamp(0, size.y);
    final tapX = cx.round();

    final cmd =
        'input tap $tapX $startY && sleep 0.1 && input swipe $tapX $startY $tapX $endY $durationMs';
    final res = await client.run(['-s', serial, 'shell', cmd]);
    return res.exitCode == 0;
  }

  static Future<bool> _streamPinch(
    ControlDatasource ds,
    String serial,
    double scale,
    double cx,
    double cy,
    Point<int> size,
    int durationMs,
  ) async {
    final frame = FrameSize(size.x, size.y);
    const span = 150.0;
    final (startSpan, endSpan) = scale >= 1.0
        ? (span, span * scale.clamp(1.2, 3.0))
        : (span / scale.clamp(0.2, 0.8), span);

    PixelPoint p1(double s) => (
      x: (cx - s / 2).round().clamp(0, size.x),
      y: (cy - s / 2).round().clamp(0, size.y),
    );
    PixelPoint p2(double s) => (
      x: (cx + s / 2).round().clamp(0, size.x),
      y: (cy + s / 2).round().clamp(0, size.y),
    );

    final ok = await ds.injectTouchStream(serial, TouchStreamPhase.start, [
      p1(startSpan),
      p2(startSpan),
    ], frame: frame);
    if (!ok) return false;

    const steps = 8;
    final stepDelay = Duration(
      milliseconds: (durationMs ~/ steps).clamp(10, 100),
    );
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDelay);
      final t = i / steps;
      final current = startSpan + (endSpan - startSpan) * t;
      await ds.injectTouchStream(serial, TouchStreamPhase.move, [
        p1(current),
        p2(current),
      ], frame: frame);
    }

    return ds.injectTouchStream(serial, TouchStreamPhase.end, [
      p1(endSpan),
      p2(endSpan),
    ], frame: frame);
  }
}
