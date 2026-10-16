part of 'mcp_adb_client.dart';

/// Helper responsible for discovering and caching the ADB binary path on macOS host.
class McpAdbResolver {
  const McpAdbResolver._();

  static final List<String> _knownPaths = [
    'adb',
    '/opt/homebrew/bin/adb',
    '/usr/local/bin/adb',
    '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb',
  ];

  /// Locates the adb executable on the local host machine.
  static Future<String?> resolve(String? cached) async {
    if (cached != null) return cached;

    try {
      final which = await Process.run('/usr/bin/which', ['adb']);
      final path = which.stdout.toString().trim();
      if (which.exitCode == 0 && path.isNotEmpty) {
        return path;
      }
    } catch (_) {}

    for (final p in _knownPaths) {
      try {
        final res = await Process.run(p, ['version']);
        if (res.exitCode == 0) {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }
}

/// Generic 2D point representation for normalized screen coordinates.
class Point<T extends num> {
  const Point(this.x, this.y);
  final T x;
  final T y;
}
