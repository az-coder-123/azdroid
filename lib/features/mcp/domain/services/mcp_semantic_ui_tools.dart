import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for UI hierarchy semantic inspection and element interactions.
final List<McpToolDefinition> mcpSemanticUiTools = [
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
    description: 'Taps an element: by id, the [#ID] from the latest android_get_ui_tree (most reliable), or by text (case-insensitive substring), resourceId, or contentDesc. Give id or at least one of the other three.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'id': {
          'type': 'integer',
          'description': '[#ID] from the latest android_get_ui_tree.',
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
      'anyOf': [
        {
          'required': ['id'],
        },
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
