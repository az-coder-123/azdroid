import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of advanced multi-touch gesture tools (pinch zoom, two-finger rotation).
final List<McpToolDefinition> mcpGestureTools = [
  const McpToolDefinition(
    name: 'android_pinch_gesture',
    annotations: inputToolAnnotations,
    description: 'Executes a two-finger pinch gesture (zoom in / zoom out) centered at specified normalized or pixel coordinates.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'scale': {
          'type': 'number',
          'description': 'Scale factor (> 1.0 to zoom in, e.g. 1.5; < 1.0 to zoom out, e.g. 0.5). Alias: scaleFactor.',
        },
        'scaleFactor': {
          'type': 'number',
          'description':
              'Alias for scale (> 1.0 to zoom in, < 1.0 to zoom out).',
        },
        'centerX': {
          'type': 'number',
          'description': 'Horizontal center (0.0..1.0 or pixels, default 0.5).',
        },
        'centerY': {
          'type': 'number',
          'description': 'Vertical center (0.0..1.0 or pixels, default 0.5).',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Gesture duration in milliseconds (default 400).',
        },
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
      },
      'required': ['scale'],
    },
  ),
  const McpToolDefinition(
    name: 'android_rotate_gesture',
    annotations: inputToolAnnotations,
    description: 'Executes a two-finger rotation gesture (clockwise / counter-clockwise) by specified degrees around a center coordinate.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'angleDegrees': {
          'type': 'number',
          'description': 'Angle of rotation in degrees (> 0 clockwise, < 0 counter-clockwise). Aliases: angle, degrees, deg.',
        },
        'angle': {'type': 'number', 'description': 'Alias for angleDegrees.'},
        'centerX': {
          'type': 'number',
          'description': 'Horizontal center (0.0..1.0 or pixels, default 0.5).',
        },
        'centerY': {
          'type': 'number',
          'description': 'Vertical center (0.0..1.0 or pixels, default 0.5).',
        },
        'radius': {
          'type': 'number',
          'description': 'Radius of two-finger touch circle in pixels or normalized ratio (default 200).',
        },
        'durationMs': {
          'type': 'integer',
          'description': 'Gesture duration in milliseconds (default 400).',
        },
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial or IP:port.',
        },
      },
      'required': ['angleDegrees'],
    },
  ),
];
