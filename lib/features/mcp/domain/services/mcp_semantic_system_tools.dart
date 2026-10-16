import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_semantic_ui_tools.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_system_tools.dart';

export 'package:desk_droid/features/mcp/domain/services/mcp_semantic_ui_tools.dart';
export 'package:desk_droid/features/mcp/domain/services/mcp_system_tools.dart';

/// Combined catalog of semantic UI tree inspection and system control tools.
final List<McpToolDefinition> mcpSemanticSystemTools = [
  ...mcpSemanticUiTools,
  ...mcpSystemTools,
];
