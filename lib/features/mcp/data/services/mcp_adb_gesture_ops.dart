part of 'mcp_adb_client.dart';

/// Static operations for advanced multi-touch gestures (pinch zoom, two-finger rotation).
class McpAdbGestureOps {
  const McpAdbGestureOps._();

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
    final size = await McpAdbInputOps.getDisplaySize(client, serial);
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
        ? (span, span * scale.clamp(1.05, 4.0))
        : (span / scale.clamp(0.1, 0.95), span);

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

  /// Injects a two-finger rotation gesture by [angleDegrees] around ([centerX], [centerY]).
  /// Uses ScrcpyControlDatasource stream when mirroring is active,
  /// falling back to dual-pointer curved swipe approximation in pure ADB.
  static Future<bool> rotateGesture(
    McpAdbClient client,
    String serial, {
    required double angleDegrees,
    double centerX = 0.5,
    double centerY = 0.5,
    double radius = 200,
    int durationMs = 400,
  }) async {
    final size = await McpAdbInputOps.getDisplaySize(client, serial);
    final cx = centerX <= 1.0 ? centerX * size.x : centerX;
    final cy = centerY <= 1.0 ? centerY * size.y : centerY;
    final r = radius <= 1.0 ? radius * size.x : radius;

    if (GetIt.I.isRegistered<ControlDatasource>()) {
      final ds = GetIt.I<ControlDatasource>();
      if (ds is ScrcpyControlDatasource && ds.isAvailableFor(serial)) {
        return _streamRotate(
          ds,
          serial,
          angleDegrees,
          cx,
          cy,
          r,
          size,
          durationMs,
        );
      }
    }

    // Pure ADB fallback: approximate rotation using tangential swipe
    final rad = angleDegrees * (pi / 180.0);
    final startX = (cx + r).round().clamp(0, size.x);
    final startY = cy.round().clamp(0, size.y);
    final endX = (cx + r * cos(rad)).round().clamp(0, size.x);
    final endY = (cy + r * sin(rad)).round().clamp(0, size.y);

    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input swipe $startX $startY $endX $endY $durationMs',
    ]);
    return res.exitCode == 0;
  }

  static Future<bool> _streamRotate(
    ControlDatasource ds,
    String serial,
    double angleDegrees,
    double cx,
    double cy,
    double radius,
    Point<int> size,
    int durationMs,
  ) async {
    final frame = FrameSize(size.x, size.y);
    final totalRad = angleDegrees * (pi / 180.0);
    const initialAngle = 0.0;

    PixelPoint p1(double angle) => (
      x: (cx + radius * cos(angle)).round().clamp(0, size.x),
      y: (cy + radius * sin(angle)).round().clamp(0, size.y),
    );
    PixelPoint p2(double angle) => (
      x: (cx - radius * cos(angle)).round().clamp(0, size.x),
      y: (cy - radius * sin(angle)).round().clamp(0, size.y),
    );

    final ok = await ds.injectTouchStream(serial, TouchStreamPhase.start, [
      p1(initialAngle),
      p2(initialAngle),
    ], frame: frame);
    if (!ok) return false;

    const steps = 8;
    final stepDelay = Duration(
      milliseconds: (durationMs ~/ steps).clamp(10, 100),
    );
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDelay);
      final t = i / steps;
      final currentAngle = initialAngle + totalRad * t;
      await ds.injectTouchStream(serial, TouchStreamPhase.move, [
        p1(currentAngle),
        p2(currentAngle),
      ], frame: frame);
    }

    final finalAngle = initialAngle + totalRad;
    return ds.injectTouchStream(serial, TouchStreamPhase.end, [
      p1(finalAngle),
      p2(finalAngle),
    ], frame: frame);
  }
}
