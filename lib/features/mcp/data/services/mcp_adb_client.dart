import 'dart:io';

/// Pure Dart ADB client for DeskDroid MCP Server.
/// Operates without UI or Flutter framework dependencies.
class McpAdbClient {
  McpAdbClient({String? explicitAdbPath}) : _cachedAdbPath = explicitAdbPath;

  String? _cachedAdbPath;

  static final List<String> _knownPaths = [
    'adb',
    '/opt/homebrew/bin/adb',
    '/usr/local/bin/adb',
    '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb',
  ];

  Future<String?> resolveAdb() async {
    if (_cachedAdbPath != null) return _cachedAdbPath;

    try {
      final which = await Process.run('/usr/bin/which', ['adb']);
      final path = which.stdout.toString().trim();
      if (which.exitCode == 0 && path.isNotEmpty) {
        _cachedAdbPath = path;
        return path;
      }
    } catch (_) {}

    for (final p in _knownPaths) {
      try {
        final res = await Process.run(p, ['version']);
        if (res.exitCode == 0) {
          _cachedAdbPath = p;
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<ProcessResult> run(List<String> args) async {
    final adb = await resolveAdb();
    if (adb == null) {
      throw const SocketException('ADB executable not found on host machine.');
    }
    return await Process.run(adb, args);
  }

  Future<List<String>> getConnectedSerials() async {
    final res = await run(['devices']);
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().split('\n');
    final serials = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1].toLowerCase() == 'device') {
        serials.add(parts[0]);
      }
    }
    return serials;
  }

  Future<String> listDevicesRaw() async {
    final res = await run(['devices', '-l']);
    return res.stdout.toString().trim();
  }

  Future<List<int>?> captureScreenshotBytes(String serial) async {
    final adb = await resolveAdb();
    if (adb == null) return null;

    final res = await Process.run(adb, ['-s', serial, 'exec-out', 'screencap', '-p'],
        stdoutEncoding: null);
    if (res.exitCode == 0 && res.stdout is List<int>) {
      return res.stdout as List<int>;
    }
    return null;
  }

  Future<Point<int>> getDisplaySize(String serial) async {
    final res = await run(['-s', serial, 'shell', 'wm', 'size']);
    final out = res.stdout.toString();
    final match = RegExp(r'Physical size:\s*(\d+)x(\d+)').firstMatch(out);
    if (match != null) {
      final w = int.parse(match.group(1)!);
      final h = int.parse(match.group(2)!);
      return Point(w, h);
    }
    return const Point(1080, 2400); // Standard mobile fallback
  }

  Future<bool> tap(String serial, double x, double y) async {
    int targetX = x.round();
    int targetY = y.round();
    if (x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0) {
      final size = await getDisplaySize(serial);
      targetX = (x * size.x).round();
      targetY = (y * size.y).round();
    }
    final res = await run(['-s', serial, 'shell', 'input', 'tap', '$targetX', '$targetY']);
    return res.exitCode == 0;
  }

  Future<bool> swipe(String serial, double sx, double sy, double ex, double ey, int durationMs) async {
    int startX = sx.round();
    int startY = sy.round();
    int endX = ex.round();
    int endY = ey.round();
    if (sx >= 0.0 && sx <= 1.0) {
      final size = await getDisplaySize(serial);
      startX = (sx * size.x).round();
      startY = (sy * size.y).round();
      endX = (ex * size.x).round();
      endY = (ey * size.y).round();
    }
    final res = await run(['-s', serial, 'shell', 'input', 'swipe', '$startX', '$startY', '$endX', '$endY', '$durationMs']);
    return res.exitCode == 0;
  }

  Future<bool> typeText(String serial, String text) async {
    final escaped = text.replaceAll(' ', '%s');
    final res = await run(['-s', serial, 'shell', 'input', 'text', escaped]);
    return res.exitCode == 0;
  }

  Future<bool> pressKey(String serial, int keyCode) async {
    final res = await run(['-s', serial, 'shell', 'input', 'keyevent', '$keyCode']);
    return res.exitCode == 0;
  }

  Future<String> dispatchIntent(String serial, String action, {String? dataUri, String? package, String? component, Map<String, dynamic>? extras}) async {
    final cmd = ['-s', serial, 'shell', 'am', 'start', '-a', action];
    if (dataUri != null && dataUri.isNotEmpty) cmd.addAll(['-d', dataUri]);
    if (package != null && package.isNotEmpty) cmd.addAll(['-p', package]);
    if (component != null && component.isNotEmpty) cmd.addAll(['-n', component]);
    if (extras != null) {
      extras.forEach((key, value) {
        if (value is bool) {
          cmd.addAll(['--ez', key, value.toString()]);
        } else if (value is int) {
          cmd.addAll(['--ei', key, value.toString()]);
        } else {
          cmd.addAll(['--es', key, value.toString()]);
        }
      });
    }
    final res = await run(cmd);
    return res.stdout.toString().trim();
  }

  Future<String> getLogcat(String serial, {String? tag, int limit = 50}) async {
    final cmd = ['-s', serial, 'logcat', '-d', '-t', '$limit'];
    if (tag != null && tag.isNotEmpty) cmd.addAll(['-s', '$tag:*']);
    final res = await run(cmd);
    return res.stdout.toString().trim();
  }

  Future<bool> installApk(String serial, String apkPath, {bool reinstall = true, bool grantPermissions = true}) async {
    final cmd = ['-s', serial, 'install'];
    if (reinstall) cmd.add('-r');
    if (grantPermissions) cmd.add('-g');
    cmd.add(apkPath);
    final res = await run(cmd);
    return res.exitCode == 0;
  }

  Future<String> shell(String serial, String command) async {
    final res = await run(['-s', serial, 'shell', command]);
    return 'Exit: ${res.exitCode}\n${res.stdout}\n${res.stderr}'.trim();
  }
}

class Point<T extends num> {
  const Point(this.x, this.y);
  final T x;
  final T y;
}
