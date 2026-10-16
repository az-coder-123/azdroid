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

  /// Queries the display's physical resolution.
  static Future<Point<int>> getDisplaySize(
    McpAdbClient client,
    String serial,
  ) async {
    final res = await client.run(['-s', serial, 'shell', 'wm', 'size']);
    final out = res.stdout.toString();
    final match = RegExp(r'Physical size:\s*(\d+)x(\d+)').firstMatch(out);
    if (match != null) {
      final w = int.parse(match.group(1)!);
      final h = int.parse(match.group(2)!);
      return Point(w, h);
    }
    return const Point(1080, 2400);
  }

  /// Injects a touch tap gesture at pixel or normalized coordinates.
  static Future<bool> tap(
    McpAdbClient client,
    String serial,
    double x,
    double y,
  ) async {
    int targetX = x.round();
    int targetY = y.round();
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

  /// Types text with space escaping.
  static Future<bool> typeText(
    McpAdbClient client,
    String serial,
    String text,
  ) async {
    final escaped = text.replaceAll(' ', '%s');
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'text',
      escaped,
    ]);
    return res.exitCode == 0;
  }

  /// Sends hardware keyevent by keycode.
  static Future<bool> pressKey(
    McpAdbClient client,
    String serial,
    int keyCode,
  ) async {
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '$keyCode',
    ]);
    return res.exitCode == 0;
  }
}
