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
      stderr.writeln('[DeskDroid MCP] ADB probe "$probe" failed: $error');

  /// Locates the adb executable on the local host machine.
  static Future<String?> resolve(String? cached) async =>
      cached ?? await _locator.locate();
}

/// Generic 2D point representation for normalized screen coordinates.
class Point<T extends num> {
  const Point(this.x, this.y);
  final T x;
  final T y;
}
