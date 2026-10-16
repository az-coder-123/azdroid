import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// MCP tool definitions for UI hierarchy semantic inspection and element interactions.
final List<McpToolDefinition> mcpSemanticUiTools = [
  const McpToolDefinition(
    name: 'android_dump_hierarchy',
    description: 'Dumps the raw active window UI accessibility hierarchy XML (classes, resource IDs, text, bounds, clickable).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_semantic_tree',
    description: 'Inspects the active window accessibility UI tree, pruning invisible and empty layouts into a compact token-efficient digest with [#ID] tags.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_click_element_by_id',
    description: 'Taps an element directly using its sequential [#ID] from the most recent android_get_semantic_tree output.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
        'id': {
          'type': 'integer',
          'description': 'Sequential element ID (e.g. 1, 2, 5) from the semantic tree digest.',
        },
      },
      'required': ['id'],
    },
  ),
  const McpToolDefinition(
    name: 'android_find_element',
    description: 'Searches the UI hierarchy for an element by text, resource ID, or content description. Returns bounds and center tap coordinates.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'text': {
          'type': 'string',
          'description':
              'Visible text to search for (case-insensitive substring match).',
        },
        'resourceId': {
          'type': 'string',
          'description': 'Android view ID to search for (e.g. "com.example:id/login_btn").',
        },
        'contentDesc': {
          'type': 'string',
          'description': 'Accessibility content description to search for.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_click_element',
    description: 'Finds an on-screen element by text, ID, or description and immediately taps its center coordinates.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'text': {
          'type': 'string',
          'description': 'Visible text of the element to click.',
        },
        'resourceId': {
          'type': 'string',
          'description': 'Resource ID of the element to click.',
        },
        'contentDesc': {
          'type': 'string',
          'description': 'Accessibility description of the element to click.',
        },
      },
    },
  ),
];
