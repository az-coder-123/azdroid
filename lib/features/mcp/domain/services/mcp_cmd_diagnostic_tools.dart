import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
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
        'deviceSerial': mcpDeviceSerialProp,
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
    description: 'Returns the most recent logcat lines (limit, default 50), optionally only one tag and only from a minimum level up (V, D, I, W, E, F).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'tag': {'type': 'string', 'description': 'Only this log tag.'},
        'level': {
          'type': 'string',
          'enum': ['V', 'D', 'I', 'W', 'E', 'F'],
          'description': 'Minimum level (default V: everything).',
        },
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
        'deviceSerial': mcpDeviceSerialProp,
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
        'deviceSerial': mcpDeviceSerialProp,
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
    description: 'Installs an APK file from the computer onto the device.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'deviceSerial': mcpDeviceSerialProp,
        'apkPath': {
          'type': 'string',
          'description': 'Absolute path of the APK on the computer.',
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
        'deviceSerial': mcpDeviceSerialProp,
        'command': {'type': 'string', 'description': 'Shell command string.'},
      },
      'required': ['command'],
    },
  ),
];
