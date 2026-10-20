import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_cmd_diagnostic_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_screen_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_touch_input_tools.dart';

export 'package:desk_droid/features/mcp/domain/services/mcp_cmd_diagnostic_tools.dart';
export 'package:desk_droid/features/mcp/domain/services/mcp_screen_tools.dart';
export 'package:desk_droid/features/mcp/domain/services/mcp_touch_input_tools.dart';

/// Catalog of basic input, screen capture, intent, and diagnostic tools for MCP.
class McpBasicTools {
  const McpBasicTools._();

  static List<McpToolDefinition> get tools => [
    ...mcpScreenTools,
    ...mcpTouchInputTools,
    ...mcpCmdDiagnosticTools,
  ];
}
