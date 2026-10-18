import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';

/// Reads the state of the DeskDroid MCP server on this computer.
abstract class McpStatusRepository {
  /// Full check: executable, AI client configurations, running sessions.
  /// Never throws; failures are reported inside the status.
  Future<McpServerStatus> load();

  /// Running server processes only (cheap, for periodic refresh); `null`
  /// when the process list cannot be read.
  Future<int?> countRunningSessions();

  /// JSON an AI client needs to launch this app's server.
  String configurationSnippet();
}
