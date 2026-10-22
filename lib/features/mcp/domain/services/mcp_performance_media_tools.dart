import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for performance telemetry, screen recording, processes, and orientation.
final List<McpToolDefinition> mcpPerformanceMediaTools = [
  const McpToolDefinition(
    name: 'android_record_screen',
    annotations: inputToolAnnotations,
    description: 'Records the screen to MP4 for durationSec seconds (default 5, max 180) and saves it on the computer at localDestination.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'durationSec': {
          'type': 'integer',
          'description':
              'Duration of the recording in seconds (default 5, max 180).',
        },
        'localDestination': {
          'type': 'string',
          'description': 'Absolute destination path on the computer (e.g. /tmp/recording.mp4).',
        },
      },
      'required': ['localDestination'],
    },
  ),
  const McpToolDefinition(
    name: 'android_set_orientation',
    annotations: stateSetToolAnnotations,
    description: 'Forces device screen rotation: 0 (Portrait), 1 (Landscape), 2 (Reverse Portrait), 3 (Reverse Landscape).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'orientation': {
          'type': 'integer',
          'enum': [0, 1, 2, 3],
          'description': 'Target orientation (0=Portrait, 1=Landscape, 2=Reverse Portrait, 3=Reverse Landscape).',
        },
      },
      'required': ['orientation'],
    },
  ),
  const McpToolDefinition(
    name: 'android_simulate_biometric',
    annotations: inputToolAnnotations,
    description: 'Simulates a fingerprint touch (success: an enrolled finger; failure: an unknown one). Works only on Android emulators (`adb emu finger touch`); physical devices return an error.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'success': {
          'type': 'boolean',
          'description': 'True to simulate authenticated biometric match, false for rejected match.',
        },
      },
    },
  ),
];
