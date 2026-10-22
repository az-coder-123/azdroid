import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_app_device_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_automation_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_basic_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_device_control_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_input_text_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_merged_device_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_performance_media_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_semantic_system_tools.dart';

/// Registry of the tools published by the Azdroid MCP server (35, under the
/// ~40-tool limit some clients apply). Each tool reaches one or more executor
/// operations through `McpToolRouter`; older tool names still run.
class McpToolRegistry {
  const McpToolRegistry();

  /// Returns the complete catalog of MCP tools for AI agents.
  List<McpToolDefinition> getTools() {
    return [
      ...McpBasicTools.tools,
      ...McpAppDeviceTools.tools,
      ...mcpSemanticSystemTools,
      ...mcpPerformanceMediaTools,
      ...McpAutomationTools.tools,
      ...McpDeviceControlTools.tools,
      ...mcpInputTextTools,
      ...mcpMergedDeviceTools,
    ];
  }
}
