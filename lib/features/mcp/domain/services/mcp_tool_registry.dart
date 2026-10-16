import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_app_device_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_automation_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_basic_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_performance_media_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_semantic_system_tools.dart';

/// Registry of all Android automation tools published by DeskDroid MCP Server.
class McpToolRegistry {
  const McpToolRegistry();

  /// Returns the complete catalog of 50 MCP tools for AI agents.
  List<McpToolDefinition> getTools() {
    return [
      ...McpBasicTools.tools,
      ...McpAppDeviceTools.tools,
      ...mcpSemanticSystemTools,
      ...mcpPerformanceMediaTools,
      ...McpAutomationTools.tools,
    ];
  }
}
