part of 'mcp_adb_client.dart';

/// One-finger approximations of pinch and rotation over `adb shell input`,
/// used only when the scrcpy touch session cannot start ([McpFastInput]
/// plays the real two-finger gestures). `input` injects a single pointer,
/// so these imitate the result, not the gesture.
class McpAdbGestureOps {
  const McpAdbGestureOps._();

  /// Zoom with Android's one-finger double-tap-and-drag gesture (Google
  /// Maps, Chrome, video players): drag down to zoom in, up to zoom out.
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

  /// A tangential swipe along the circle of [radius] around the center.
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
}
