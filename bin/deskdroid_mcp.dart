import 'package:desk_droid/features/mcp/data/transports/mcp_stdio_transport.dart';

/// Entrypoint for DeskDroid Model Context Protocol (MCP) Server.
/// Communicates over standard I/O (stdin/stdout) adhering to JSON-RPC 2.0.
void main(List<String> args) async {
  final transport = McpStdioTransport();
  await transport.run();
}
