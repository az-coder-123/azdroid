import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// MCP tool definitions for performance telemetry, screen recording, processes, and orientation.
final List<McpToolDefinition> mcpPerformanceMediaTools = [
  const McpToolDefinition(
    name: 'android_get_cpu_usage',
    annotations: readOnlyToolAnnotations,
    description: 'Samples CPU consumption for a specific package or top 10 system processes.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'package': {
          'type': 'string',
          'description': 'Optional package name to filter CPU consumption for.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_memory_info',
    annotations: readOnlyToolAnnotations,
    description: 'Dumps detailed memory allocation (PSS, Dalvik heap, Native heap, Views) for an application package.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'package': {
          'type': 'string',
          'description': 'Target package name (e.g., com.example.app).',
        },
      },
      'required': ['package'],
    },
  ),
  const McpToolDefinition(
    name: 'android_get_battery_stats',
    annotations: readOnlyToolAnnotations,
    description: 'Retrieves comprehensive battery metrics including level, temperature, voltage, health, and charging source.',
    inputSchema: {
      'type': 'object',
      'properties': {'deviceSerial': mcpDeviceSerialProp},
    },
  ),
  const McpToolDefinition(
    name: 'android_get_gfx_info',
    annotations: readOnlyToolAnnotations,
    description: 'Queries Android Choreographer / RenderThread frame rendering statistics and jank metrics for an app.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'package': {'type': 'string', 'description': 'Target package name.'},
      },
      'required': ['package'],
    },
  ),
  const McpToolDefinition(
    name: 'android_get_network_info',
    annotations: readOnlyToolAnnotations,
    description: 'Discovers network parameters including local IP address, Wi-Fi SSID, and wireless link speed.',
    inputSchema: {
      'type': 'object',
      'properties': {'deviceSerial': mcpDeviceSerialProp},
    },
  ),
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
    name: 'android_list_processes',
    annotations: readOnlyToolAnnotations,
    description: 'Lists active running Android processes with their PIDs and package names.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'filter': {
          'type': 'string',
          'description': 'Optional keyword to filter process names by.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_kill_process',
    annotations: destructiveToolAnnotations,
    description: 'Stops an app or a process. With package, force-stops the app (like android_stop_app); with pid, sends `kill`, which works only on processes the adb shell owns unless the device is rooted. Give package or pid.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'pid': {
          'type': 'integer',
          'description': 'Numeric process ID (PID) to kill.',
        },
        'package': {
          'type': 'string',
          'description': 'Package name to terminate if PID is unknown.',
        },
      },
      'anyOf': [
        {
          'required': ['pid'],
        },
        {
          'required': ['package'],
        },
      ],
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
