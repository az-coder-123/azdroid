import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog entry for text entry (paste, type, or clear) for MCP.
final List<McpToolDefinition> mcpInputTextTools = [
  const McpToolDefinition(
    name: 'android_input_text',
    annotations: inputToolAnnotations,
    description:
        'Enters text in the focused field, or in element elementId from the '
        'UI tree. method "paste" (default) pastes the exact text through the '
        'device clipboard, replacing it, so IMEs such as Telex cannot alter '
        'it; where adb cannot set the clipboard (no `cmd clipboard`, as on '
        'the Android 10 and 13 devices tested) ASCII is typed instead and '
        'other text fails, and the result says which. method "type" sends '
        'key events, ASCII only, and keeps the clipboard. An empty text '
        'clears the field.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'text': {
          'type': 'string',
          'description': 'Text to enter; empty to clear the field.',
        },
        'method': {
          'type': 'string',
          'enum': ['paste', 'type'],
          'description': 'paste (default, any text) or type (ASCII only).',
        },
        'elementId': {
          'type': 'integer',
          'description':
              'Element [#ID] from android_get_ui_tree to focus first.',
        },
        'clearFirst': {
          'type': 'boolean',
          'description': 'Clear the existing text first (default false).',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['text'],
    },
  ),
];
