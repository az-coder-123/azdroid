import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of two-finger gestures for MCP.
final List<McpToolDefinition> mcpGestureTools = [
  const McpToolDefinition(
    name: 'android_multitouch_gesture',
    annotations: inputToolAnnotations,
    description:
        'Two-finger gesture around a center point: gesture "pinch" zooms by '
        'scale (> 1 in, < 1 out); gesture "rotate" turns by angleDegrees '
        '(positive = clockwise). centerX/centerY and radius are screen '
        'fractions when within 0.0-1.0, otherwise pixels.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'gesture': {
          'type': 'string',
          'enum': ['pinch', 'rotate'],
          'description': 'Which gesture to perform.',
        },
        'scale': {
          'type': 'number',
          'description': 'Pinch: zoom factor, e.g. 1.5 in or 0.5 out.',
        },
        'angleDegrees': {
          'type': 'number',
          'description': 'Rotate: angle in degrees (> 0 clockwise).',
        },
        'centerX': {'type': 'number', 'description': 'Center X (default 0.5).'},
        'centerY': {'type': 'number', 'description': 'Center Y (default 0.5).'},
        'radius': {
          'type': 'number',
          'description':
              'Rotate: finger distance from the center (default 200 px).',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Gesture duration in ms (default 400).',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['gesture'],
    },
  ),
];
