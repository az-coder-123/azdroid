part of 'mcp_adb_client.dart';

/// Helper responsible for discovering the ADB binary path for the MCP server.
///
/// Probe failures are written to stderr because stdout carries the MCP
/// JSON-RPC stream.
class McpAdbResolver {
  const McpAdbResolver._();

  static final AdbBinaryLocator _locator = AdbBinaryLocator(
    onProbeFailure: _logProbe,
  );

  static void _logProbe(String probe, Object error) =>
      stderr.writeln('[Azdroid MCP] ADB probe "$probe" failed: $error');

  /// Locates the adb executable on the local host machine.
  ///
  /// Logs the choice to stderr once, so MCP client logs show whether the
  /// installed or the bundled adb is used.
  static Future<String?> resolve(String? cached) async {
    if (cached != null) return cached;
    final path = await _locator.locate();
    if (path == null) {
      stderr.writeln('[Azdroid MCP] No adb found (installed or bundled).');
    } else {
      final source = path == _locator.toolchain.bundledAdbPath
          ? 'bundled'
          : 'installed';
      stderr.writeln('[Azdroid MCP] Using $source adb at $path');
    }
    return path;
  }
}

/// Generic 2D point representation for normalized screen coordinates.
class Point<T extends num> {
  const Point(this.x, this.y);
  final T x;
  final T y;
}
