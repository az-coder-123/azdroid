import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of screen capture and device enumeration tools for MCP.
final List<McpToolDefinition> mcpScreenTools = [
  const McpToolDefinition(
    name: 'android_list_devices',
    annotations: readOnlyToolAnnotations,
    description: 'Lists the devices adb can reach (`adb devices -l`): serial, state, and model. Call it first and pass a serial as deviceSerial; tools refuse to guess when several devices are connected.',
    inputSchema: {'type': 'object', 'properties': {}},
  ),
  const McpToolDefinition(
    name: 'android_take_screenshot',
    annotations: readOnlyToolAnnotations,
    description: 'Captures the screen as PNG or JPEG. Optionally crops it to save tokens: give x/y/width/height in pixels, or xRatio/yRatio/widthRatio/heightRatio as screen fractions (all four of one kind). Omit them for the full screen.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'x': {'type': 'number', 'description': 'Crop left edge in pixels.'},
        'y': {'type': 'number', 'description': 'Crop top edge in pixels.'},
        'width': {'type': 'number', 'description': 'Crop width in pixels.'},
        'height': {'type': 'number', 'description': 'Crop height in pixels.'},
        'xRatio': {
          'type': 'number',
          'description': 'Crop origin X ratio (0.0 to 1.0).',
        },
        'yRatio': {
          'type': 'number',
          'description': 'Crop origin Y ratio (0.0 to 1.0).',
        },
        'widthRatio': {
          'type': 'number',
          'description': 'Crop width ratio (0.0 to 1.0).',
        },
        'heightRatio': {
          'type': 'number',
          'description': 'Crop height ratio (0.0 to 1.0).',
        },
        'format': {
          'type': 'string',
          'enum': ['png', 'jpeg', 'jpg'],
          'description': 'Output image format (default png).',
        },
        'quality': {
          'type': 'integer',
          'description': 'JPEG compression quality from 1 to 100 (default 80).',
        },
      },
    },
  ),
];
