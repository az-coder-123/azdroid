import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';

/// An AI client that can launch the Azdroid MCP server, and the file in
/// which it lists its MCP servers (`mcpServers` JSON object).
typedef McpClientLocation = ({String name, String configPath});

/// Where each supported AI client keeps its user-level MCP configuration on
/// the host OS. Plain data, so callers never branch on the OS.
///
/// Pure Dart (no Flutter).
class McpClientLocations {
  const McpClientLocations(this.clients);

  factory McpClientLocations.forHost({
    required HostOs os,
    required HostPaths paths,
    required Map<String, String> environment,
  }) {
    final ctx = paths.context;
    final home = paths.homeDirectory;
    final claudeRoot = switch (os) {
      HostOs.macos => ctx.join(home, 'Library', 'Application Support'),
      HostOs.windows =>
        environment['APPDATA'] ?? ctx.join(home, 'AppData', 'Roaming'),
      HostOs.linux =>
        environment['XDG_CONFIG_HOME'] ?? ctx.join(home, '.config'),
    };
    return McpClientLocations([
      (
        name: 'Claude Desktop',
        configPath: ctx.join(
          claudeRoot,
          'Claude',
          'claude_desktop_config.json',
        ),
      ),
      (name: 'Cursor', configPath: ctx.join(home, '.cursor', 'mcp.json')),
      (
        name: 'Antigravity',
        configPath: ctx.join(home, '.gemini', 'antigravity', 'mcp_config.json'),
      ),
    ]);
  }

  /// Known clients, in the order the status panel lists them.
  final List<McpClientLocation> clients;
}
