import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Catalog of Intent dispatching, logcat inspection, APK installation, and shell execution tools.
final List<McpToolDefinition> mcpCmdDiagnosticTools = [
  const McpToolDefinition(
    name: 'android_dispatch_intent',
    annotations: inputToolAnnotations,
    description: 'Fires an Android Intent, custom URL scheme, or deep link with optional package and typed extras.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'action': {
          'type': 'string',
          'description': 'Intent action (e.g., android.intent.action.VIEW).',
        },
        'dataUri': {'type': 'string', 'description': 'Data URI or web URL.'},
        'package': {
          'type': 'string',
          'description': 'Target application package name.',
        },
        'component': {
          'type': 'string',
          'description': 'Explicit target component class.',
        },
        'extras': {
          'type': 'object',
          'description': 'Key-value map of intent extras.',
        },
      },
      'required': ['action'],
    },
  ),
  const McpToolDefinition(
    name: 'android_get_logcat',
    annotations: readOnlyToolAnnotations,
    description: 'Extracts real-time or recent logcat records from the device with optional tag and level filtering.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'tag': {'type': 'string', 'description': 'Filter by tag.'},
        'limit': {
          'type': 'integer',
          'description':
              'Maximum number of log lines to retrieve (default 50).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_check_crash',
    annotations: readOnlyToolAnnotations,
    description: 'Inspects the Android dedicated crash buffer (-b crash), runtime fatal exceptions, or ANRs for a target package, returning clean crash traces.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'package': {
          'type': 'string',
          'description':
              'Target application package name to filter crash logs for.',
        },
        'limit': {
          'type': 'integer',
          'description':
              'Maximum number of crash log lines to retrieve (default 50).',
        },
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_scan_media_file',
    annotations: inputToolAnnotations,
    description: 'Triggers Android MediaStore to scan and index a newly pushed or modified audio/video file so media apps immediately discover it.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'filePath': {
          'type': 'string',
          'description': 'Absolute path to the media file on device (e.g., /sdcard/Music/song.mp3).',
        },
      },
      'required': ['filePath'],
    },
  ),
  const McpToolDefinition(
    name: 'android_install_apk',
    annotations: destructiveToolAnnotations,
    description: 'Sideloads an APK package onto the Android device.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'apkPath': {
          'type': 'string',
          'description': 'Absolute path to APK on host Mac.',
        },
        'reinstall': {
          'type': 'boolean',
          'description': 'Allow reinstall keeping existing data.',
        },
        'grantPermissions': {
          'type': 'boolean',
          'description': 'Auto-grant runtime permissions.',
        },
      },
      'required': ['apkPath'],
    },
  ),
  const McpToolDefinition(
    name: 'android_shell_command',
    annotations: destructiveToolAnnotations,
    description: 'Executes a raw adb shell command on the Android device for advanced troubleshooting.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': {
          'type': 'string',
          'description': 'Target device serial.',
        },
        'command': {'type': 'string', 'description': 'Shell command string.'},
      },
      'required': ['command'],
    },
  ),
];
