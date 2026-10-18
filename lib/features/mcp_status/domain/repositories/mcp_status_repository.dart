import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';

/// Reads the state of the DeskDroid MCP server on this computer.
abstract class McpStatusRepository {
  /// Full check: executable, AI client configurations, running sessions,
  /// activity. Never throws; failures are reported inside the status.
  Future<McpServerStatus> load();

  /// Ids of running server processes (one per AI session); `null` when the
  /// process list cannot be read. Also removes stale activity files.
  Future<Set<int>?> listServerPids();

  /// What the sessions are doing now, from their activity files (cheap,
  /// for frequent refresh).
  Future<McpActivitySnapshot> readActivity({required Set<int>? livePids});

  /// JSON an AI client needs to launch this app's server.
  String configurationSnippet();
}
