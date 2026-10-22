import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/mcp_activity_paths.dart';
import 'package:desk_droid/features/mcp/data/handlers/mcp_protocol_handler.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_activity_recorder.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_scrcpy_touch_session.dart';
import 'package:desk_droid/features/mcp/data/transports/mcp_stdio_transport.dart';

/// Entrypoint for Azdroid Model Context Protocol (MCP) Server.
/// Communicates over standard I/O (stdin/stdout) adhering to JSON-RPC 2.0.
///
/// Records which tools it runs on which device in a per-process activity
/// file, so the Azdroid app can show it (docs/features/mcp-activity-log.md).
void main(List<String> args) async {
  final activity = FileMcpActivityRecorder(
    filePath: McpActivityPaths(SystemHostPaths()).fileFor(pid),
  );
  final transport = McpStdioTransport(
    handler: McpProtocolHandler(activity: activity),
  );
  await transport.run();
  // The client closed stdin: stop the device sessions this process owns.
  await McpScrcpyTouchSession.closeAll();
}
