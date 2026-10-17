import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Catalog of Intent dispatching, logcat inspection, APK installation, and shell execution tools.
final List<McpToolDefinition> mcpCmdDiagnosticTools = [
  const McpToolDefinition(
    name: 'android_dispatch_intent',
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
    name: 'android_install_apk',
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
