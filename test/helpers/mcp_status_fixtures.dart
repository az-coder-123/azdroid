import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';

const String fixtureMcpExecutable =
    '/Applications/Azdroid.app/Contents/MacOS/azdroid-mcp';

/// An MCP status for tests; defaults to a ready server, Claude Desktop set
/// up, and no running session.
McpServerStatus mcpStatus({
  McpBinaryAvailability availability = McpBinaryAvailability.ready,
  McpClientSetup claude = McpClientSetup.configured,
  Set<int>? livePids = const {},
  McpActivitySnapshot activity = const McpActivitySnapshot(),
  List<String> architectures = const ['x86_64'],
}) => McpServerStatus(
  binary: McpBinaryStatus(
    availability: availability,
    executablePath: fixtureMcpExecutable,
    architectures: architectures,
  ),
  clients: [
    McpClientStatus(
      name: 'Claude Desktop',
      configPath: '/Users/dev/Library/Application Support/Claude/claude_desktop_config.json',
      setup: claude,
    ),
    const McpClientStatus(
      name: 'Cursor',
      configPath: '/Users/dev/.cursor/mcp.json',
      setup: McpClientSetup.clientNotFound,
    ),
    const McpClientStatus(
      name: 'Antigravity',
      configPath: '/Users/dev/.gemini/antigravity/mcp_config.json',
      setup: McpClientSetup.configuredElsewhere,
      configuredCommand: 'dart run /src/bin/azdroid_mcp.dart',
    ),
  ],
  livePids: livePids,
  activity: activity,
);
