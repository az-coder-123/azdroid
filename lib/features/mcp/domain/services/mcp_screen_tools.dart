import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of screen capture and device enumeration tools for MCP.
final List<McpToolDefinition> mcpScreenTools = [
  const McpToolDefinition(
    name: 'android_list_devices',
    annotations: readOnlyToolAnnotations,
    description:
        'Lists all connected and discovered Android devices via USB and Wi-Fi.',
    inputSchema: {'type': 'object', 'properties': {}},
  ),
  const McpToolDefinition(
    name: 'android_take_screenshot',
    annotations: readOnlyToolAnnotations,
    description: 'Captures a high-resolution screenshot with optional Region-of-Interest (ROI) cropping and JPEG/PNG compression to save up to 85% Vision tokens.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Device serial or IP:port (optional if only one device is connected).',
        },
        'crop': {
          'type': 'object',
          'description': 'Optional pixel or ratio bounding box: {"x": 0, "y": 0, "width": 500, "height": 500}.',
          'properties': {
            'x': {'type': 'number', 'description': 'X coordinate or ratio.'},
            'y': {'type': 'number', 'description': 'Y coordinate or ratio.'},
            'width': {'type': 'number', 'description': 'Width or width ratio.'},
            'height': {
              'type': 'number',
              'description': 'Height or height ratio.',
            },
          },
        },
        'x': {
          'type': 'number',
          'description': 'Crop origin X (pixels or normalized 0.0..1.0).',
        },
        'y': {
          'type': 'number',
          'description': 'Crop origin Y (pixels or normalized 0.0..1.0).',
        },
        'width': {
          'type': 'number',
          'description': 'Crop width (pixels or normalized 0.0..1.0).',
        },
        'height': {
          'type': 'number',
          'description': 'Crop height (pixels or normalized 0.0..1.0).',
        },
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
