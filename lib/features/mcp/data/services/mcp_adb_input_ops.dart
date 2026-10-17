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

  /// Types text with space escaping (character-by-character via IME).
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

  /// Injects exact text bypassing IME predictive engines and Telex autocorrect.
  static Future<bool> setText(
    McpAdbClient client,
    String serial,
    String text, {
    int? elementId,
    bool clearFirst = false,
  }) async {
    if (elementId != null) {
      final tapped = await client.clickElementById(serial, elementId);
      if (!tapped) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (clearFirst) {
      await clearText(client, serial);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Set Android system clipboard and paste as atomic block.
    final copied = await client.setClipboard(serial, text);
    if (!copied) {
      return await typeText(client, serial, text);
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '279',
    ]);
    return res.exitCode == 0;
  }

  /// Clears text in the focused field or focuses an element by ID before clearing.
  static Future<bool> clearText(
    McpAdbClient client,
    String serial, {
    int? elementId,
  }) async {
    if (elementId != null) {
      final tapped = await client.clickElementById(serial, elementId);
      if (!tapped) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Move to end, Select All (Ctrl+A), and Delete (DEL) in a single shell invocation.
    const cmd =
        'input keyevent 123 && input keyevent --meta 4096 29 && input keyevent 67';
    final res = await client.run(['-s', serial, 'shell', cmd]);
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
