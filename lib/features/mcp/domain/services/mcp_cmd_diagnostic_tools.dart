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
    description: 'Returns the newest logcat lines (limit, default 50), optionally only one tag and only from a minimum level up (V, D, I, W, E, F). With crashesOnly: true, returns crash traces and ANRs from the crash buffer instead, optionally for one package.',
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
        'crashesOnly': {
          'type': 'boolean',
          'description': 'Crash buffer only: crashes and ANRs (default false).',
        },
        'package': {
          'type': 'string',
          'description': 'crashesOnly: only this app.',
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
