import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog entries that each cover a family of device operations (see
/// `McpToolRouter` for how they map onto the executors).
final List<McpToolDefinition> mcpMergedDeviceTools = [
  const McpToolDefinition(
    name: 'android_get_ui_tree',
    annotations: readOnlyToolAnnotations,
    description:
        'Reads the active window UI. format "semantic" (default): a compact '
        'digest with [#ID] tags for android_click_element and '
        'android_input_text. format "xml": the raw accessibility XML '
        '(classes, resource IDs, bounds).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'format': {
          'type': 'string',
          'enum': ['semantic', 'xml'],
          'description': 'semantic (default) or xml.',
        },
        'compressed': {
          'type': 'boolean',
          'description':
              'xml only: merge layout containers (default true); false for '
              'full Compose/Flutter trees.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_list_apps',
    annotations: readOnlyToolAnnotations,
    description:
        'Lists installed packages (third-party only by default), or with '
        'running: true the running processes with their PIDs. query filters '
        'by name.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'running': {
          'type': 'boolean',
          'description': 'List running processes instead (default false).',
        },
        'thirdPartyOnly': {
          'type': 'boolean',
          'description': 'Packages only: skip system apps (default true).',
        },
        'query': {'type': 'string', 'description': 'Name substring filter.'},
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_get_device_stats',
    annotations: readOnlyToolAnnotations,
    description:
        'Reads one kind of device data: device (model, Android version, '
        'screen, battery %), battery (level, temperature, health, charger), '
        'network (IP, Wi-Fi SSID, link speed), cpu (top processes or one '
        'package), memory (PSS and heaps of a package), gfx (frame and jank '
        'stats of a package).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'kind': {
          'type': 'string',
          'enum': ['device', 'battery', 'network', 'cpu', 'memory', 'gfx'],
          'description': 'Which data to read.',
        },
        'package': {
          'type': 'string',
          'description': 'Required for memory and gfx; optional for cpu.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['kind'],
    },
  ),
  const McpToolDefinition(
    name: 'android_set_network',
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Changes connectivity: normal, offline, wifi_only, data_only, '
        'wifi_on, wifi_off, airplane_on, airplane_off. offline, data_only, '
        'wifi_off, and airplane_on cut Wi-Fi and drop a Wi-Fi ADB '
        'connection, with no remote way back: use them over USB, or '
        'confirm first.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'mode': {
          'type': 'string',
          'enum': [
            'normal',
            'offline',
            'wifi_only',
            'data_only',
            'wifi_on',
            'wifi_off',
            'airplane_on',
            'airplane_off',
          ],
          'description': 'Target connectivity.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['mode'],
    },
  ),
  const McpToolDefinition(
    name: 'android_set_permission',
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Grants (grant: true) or revokes (grant: false) a runtime permission '
        'of an app. Revoking a granted permission makes Android kill the app '
        'process, so unsaved app state is lost.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'package': {'type': 'string', 'description': 'App package name.'},
        'permission': {
          'type': 'string',
          'description': 'e.g. android.permission.CAMERA.',
        },
        'grant': {
          'type': 'boolean',
          'description': 'true to grant, false to revoke.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['package', 'permission', 'grant'],
    },
  ),
  const McpToolDefinition(
    name: 'android_clipboard',
    annotations: stateSetToolAnnotations,
    description:
        'Reads the device clipboard, or replaces it when text is given. '
        'Needs the `cmd clipboard` shell command, which many devices lack '
        '(the Android 10 and 13 devices tested): then it returns an error '
        'saying so.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'text': {
          'type': 'string',
          'description': 'New clipboard text; omit to read it.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_transfer_file',
    annotations: destructiveStateSetToolAnnotations,
    description:
        'Copies a file: direction "push" (computer to device) or "pull" '
        '(device to computer), overwriting the destination without asking. '
        'direction "scan" indexes remotePath in MediaStore so media apps see '
        'a new file.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'direction': {
          'type': 'string',
          'enum': ['push', 'pull', 'scan'],
          'description': 'push, pull, or scan.',
        },
        'localPath': {
          'type': 'string',
          'description': 'push/pull: absolute path on the computer.',
        },
        'remotePath': {
          'type': 'string',
          'description':
              'Absolute path on the device, e.g. /sdcard/Download/a.jpg.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['direction', 'remotePath'],
    },
  ),
];
