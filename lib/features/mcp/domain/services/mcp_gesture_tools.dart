import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of advanced multi-touch gesture tools (pinch zoom, two-finger rotation).
final List<McpToolDefinition> mcpGestureTools = [
  const McpToolDefinition(
    name: 'android_pinch_gesture',
    annotations: inputToolAnnotations,
    description: 'Two-finger pinch around a center point: scale > 1 zooms in, < 1 zooms out. centerX/centerY are screen fractions when within 0.0-1.0, otherwise pixels.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'scale': {
          'type': 'number',
          'description': 'Scale factor (> 1.0 zooms in, e.g. 1.5; < 1.0 zooms out, e.g. 0.5).',
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
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['scale'],
    },
  ),
  const McpToolDefinition(
    name: 'android_rotate_gesture',
    annotations: inputToolAnnotations,
    description: 'Two-finger rotation by angleDegrees (positive = clockwise) around a center point. centerX/centerY and radius are screen fractions when within 0.0-1.0, otherwise pixels.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'angleDegrees': {
          'type': 'number',
          'description': 'Angle of rotation in degrees (> 0 clockwise, < 0 counter-clockwise).',
        },
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
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['angleDegrees'],
    },
  ),
];
