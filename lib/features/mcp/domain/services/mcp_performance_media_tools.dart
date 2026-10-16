import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// MCP tool definitions for performance telemetry, screen recording, processes, and orientation.
final List<McpToolDefinition> mcpPerformanceMediaTools = [
  const McpToolDefinition(
    name: 'android_get_cpu_usage',
    description: 'Samples CPU consumption for a specific package or top 10 system processes.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'package': {
          'type': 'string',
          'description': 'Optional package name to filter CPU consumption for.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_memory_info',
    description: 'Dumps detailed memory allocation (PSS, Dalvik heap, Native heap, Views) for an application package.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
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
    description: 'Retrieves comprehensive battery metrics including level, temperature, voltage, health, and charging source.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_gfx_info',
    description: 'Queries Android Choreographer / RenderThread frame rendering statistics and jank metrics for an app.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'package': {'type': 'string', 'description': 'Target package name.'},
      },
      'required': ['package'],
    },
  ),
  const McpToolDefinition(
    name: 'android_get_network_info',
    description: 'Discovers network parameters including local IP address, Wi-Fi SSID, and wireless link speed.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_record_screen',
    description: 'Captures a screen video recording (MP4) for a specified duration and downloads it to the Mac host filesystem.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'durationSec': {
          'type': 'integer',
          'description':
              'Duration of the recording in seconds (default 5, max 180).',
        },
        'localDestination': {
          'type': 'string',
          'description': 'Absolute local destination file path on Mac (e.g. /tmp/recording.mp4).',
        },
      },
      'required': ['localDestination'],
    },
  ),
  const McpToolDefinition(
    name: 'android_list_processes',
    description: 'Lists active running Android processes with their PIDs and package names.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'filter': {
          'type': 'string',
          'description': 'Optional keyword to filter process names by.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_kill_process',
    description:
        'Terminates an active process by its numeric PID or package name.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'pid': {
          'type': 'integer',
          'description': 'Numeric process ID (PID) to kill.',
        },
        'package': {
          'type': 'string',
          'description': 'Package name to terminate if PID is unknown.',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_set_orientation',
    description: 'Forces device screen rotation: 0 (Portrait), 1 (Landscape), 2 (Reverse Portrait), 3 (Reverse Landscape).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
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
    description: 'Simulates biometric prompt authentication (fingerprint or face recognition) success or failure.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'success': {
          'type': 'boolean',
          'description': 'True to simulate authenticated biometric match, false for rejected match.',
        },
      },
    },
  ),
];
