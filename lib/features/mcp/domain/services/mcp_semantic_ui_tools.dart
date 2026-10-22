import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for UI hierarchy semantic inspection and element interactions.
final List<McpToolDefinition> mcpSemanticUiTools = [
  const McpToolDefinition(
    name: 'android_dump_hierarchy',
    annotations: readOnlyToolAnnotations,
    description: 'Dumps the raw active window UI accessibility hierarchy XML (classes, resource IDs, text, bounds, clickable).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'compressed': {
          'type': 'boolean',
          'description': 'Whether to compress layout containers (default true). Set to false to dump full uncompressed Compose/Flutter trees.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_semantic_tree',
    annotations: readOnlyToolAnnotations,
    description: 'Inspects the active window accessibility UI tree, pruning invisible and empty layouts into a compact token-efficient digest with [#ID] tags.',
    inputSchema: {
      'type': 'object',
      'properties': {'deviceSerial': mcpDeviceSerialProp},
    },
  ),
  const McpToolDefinition(
    name: 'android_click_element_by_id',
    annotations: inputToolAnnotations,
    description: 'Taps an element directly using its sequential [#ID] from the most recent android_get_semantic_tree output.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
    annotations: readOnlyToolAnnotations,
    description: 'Finds an element by text (case-insensitive substring), resourceId, or contentDesc and returns its bounds and center. Give at least one of the three.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
      'anyOf': [
        {
          'required': ['text'],
        },
        {
          'required': ['resourceId'],
        },
        {
          'required': ['contentDesc'],
        },
      ],
    },
  ),
  const McpToolDefinition(
    name: 'android_click_element',
    annotations: inputToolAnnotations,
    description: 'Finds an element by text, resourceId, or contentDesc and taps its center. Give at least one of the three.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
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
      'anyOf': [
        {
          'required': ['text'],
        },
        {
          'required': ['resourceId'],
        },
        {
          'required': ['contentDesc'],
        },
      ],
    },
  ),
];
