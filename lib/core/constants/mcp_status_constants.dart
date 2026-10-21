/// Facts the app uses to report the state of the bundled MCP server.
///
/// Pure Dart (no Flutter). Behavior: docs/features/mcp-status-panel.md.
class McpStatusConstants {
  const McpStatusConstants._();

  /// Base name of the precompiled server inside the app (`.exe` on Windows).
  static const String executableBaseName = 'azdroid-mcp';

  /// Legacy binary name for backwards compatibility.
  static const String legacyExecutableBaseName = 'deskdroid-mcp';

  /// Entry point that `dart run` (or `scripts/start_mcp_server.sh`) runs
  /// from a source checkout; counted as a running server too.
  static const String sourceEntryPoint = 'azdroid_mcp.dart';

  /// Legacy entry point for backwards compatibility.
  static const String legacySourceEntryPoint = 'deskdroid_mcp.dart';

  /// Launcher script for a source checkout (`scripts/start_mcp_server.sh`).
  static const String startScriptName = 'start_mcp_server.sh';

  /// Name under which the copied configuration registers the server.
  static const String configServerKey = 'azdroid';

  /// Legacy config server key.
  static const String legacyConfigServerKey = 'deskdroid';

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

  /// Folder (under the per-user app data folder) holding one activity file
  /// per running server: `<pid>.jsonl`.
  static const String activityFolderName = 'mcp-activity';

  /// Extension of an activity file.
  static const String activityFileExtension = '.jsonl';

  /// When an activity file reaches this many lines, the server rewrites it
  /// with the session start and the newest [activityKeptLines] lines.
  static const int activityMaxLines = 500;
  static const int activityKeptLines = 100;

  /// How often the app reads the activity files while it is open.
  static const Duration activityPollInterval = Duration(seconds: 1);

  /// A device counts as "AI-controlled" this long after the last tool call
  /// on it.
  static const Duration activeWindow = Duration(seconds: 10);

  /// Files of servers that no longer run are deleted once this old.
  static const Duration staleActivityAge = Duration(minutes: 10);

  /// Recent tool calls listed in the status panel, across sessions.
  static const int recentActivityLimit = 12;

  /// Architecture name of Apple Silicon in `lipo -archs` output.
  static const String appleSiliconArchitecture = 'arm64';
}
