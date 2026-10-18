/// Facts the app uses to report the state of the bundled MCP server.
///
/// Pure Dart (no Flutter). Behavior: docs/features/mcp-status-panel.md.
class McpStatusConstants {
  const McpStatusConstants._();

  /// Base name of the precompiled server inside the app (`.exe` on Windows).
  static const String executableBaseName = 'deskdroid-mcp';

  /// Entry point that `dart run` (or `scripts/start_mcp_server.sh`) runs
  /// from a source checkout; counted as a running server too.
  static const String sourceEntryPoint = 'deskdroid_mcp.dart';

  /// Launcher script for a source checkout (`scripts/start_mcp_server.sh`).
  static const String startScriptName = 'start_mcp_server.sh';

  /// Name under which the copied configuration registers the server.
  static const String configServerKey = 'deskdroid';

  /// The handshake sent to check that the server starts and answers.
  static const String handshakeRequest =
      '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}';

  /// Text a working server includes in its handshake reply.
  static const String handshakeReplyMarker = '"tools"';

  /// Upper bound for the handshake (a cold start under Rosetta is slow).
  static const Duration handshakeTimeout = Duration(seconds: 10);

  /// Upper bound for architecture and process-list commands.
  static const Duration queryTimeout = Duration(seconds: 3);

  /// How often the running-session count refreshes while the app is open.
  static const Duration sessionPollInterval = Duration(seconds: 10);

  /// Architecture name of Apple Silicon in `lipo -archs` output.
  static const String appleSiliconArchitecture = 'arm64';
}
