import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_schema_fragments.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_annotations.dart';

/// Tools for building apps and games: find pictures on screens without a UI
/// tree, run the app's tests, and change display settings.
final List<McpToolDefinition> mcpDevTools = [
  const McpToolDefinition(
    name: 'android_find_image',
    annotations: readOnlyToolAnnotations,
    description:
        'Finds a picture on the screen and returns its center for '
        'android_tap: for games and canvases, which have no UI tree. The '
        'template is an image file (templatePath, e.g. a sprite from the '
        'project) or a screen region saved earlier (templateName). To save '
        'one, pass saveAs with x, y, width, height (pixels) or xRatio, '
        'yRatio, widthRatio, heightRatio; it is kept in memory until the '
        'server stops. Sizes 0.5×–3× are tried when the template does not '
        'match at its own size; rotation is not.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'templatePath': {
          'type': 'string',
          'description': 'PNG or JPEG file on the computer.',
        },
        'templateName': {
          'type': 'string',
          'description': 'A template saved with saveAs.',
        },
        'threshold': {
          'type': 'number',
          'description':
              'Minimum score, 0–1 (default 0.8). The best candidate is '
              'reported either way.',
        },
        'scale': {
          'type': 'number',
          'description':
              'Template size on screen relative to the file, if known '
              '(skips the size search).',
        },
        'saveAs': {
          'type': 'string',
          'description': 'Save a screen region as a template under this name.',
        },
        'x': {'type': 'number', 'description': 'saveAs: left, pixels.'},
        'y': {'type': 'number', 'description': 'saveAs: top, pixels.'},
        'width': {'type': 'number', 'description': 'saveAs: width, pixels.'},
        'height': {'type': 'number', 'description': 'saveAs: height, pixels.'},
        'xRatio': mcpCoordRatioProp,
        'yRatio': mcpCoordRatioProp,
        'widthRatio': mcpCoordRatioProp,
        'heightRatio': mcpCoordRatioProp,
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
  const McpToolDefinition(
    name: 'android_run_instrumentation',
    annotations: inputToolAnnotations,
    description:
        'Runs the on-device tests of an app (`am instrument`: Espresso, UI '
        'Automator, Flutter integration_test) and returns passed/failed '
        'counts with each failure\'s stack. The test APK must be installed '
        '(e.g. ./gradlew installDebugAndroidTest). The tests run your code '
        'and may change the app\'s data. Stops after timeoutSec.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'package': {
          'type': 'string',
          'description': 'The app under test, e.g. com.example.app.',
        },
        'runner': {
          'type': 'string',
          'description':
              'test.package/RunnerClass (default: the installed runner '
              'targeting package).',
        },
        'testClass': {
          'type': 'string',
          'description':
              'Only this class or method: com.example.LoginTest or '
              'com.example.LoginTest#signsIn.',
        },
        'timeoutSec': {
          'type': 'integer',
          'description': 'Stop the run after this many seconds (default 600).',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
      'required': ['package'],
    },
  ),
  const McpToolDefinition(
    name: 'android_set_display_config',
    annotations: stateSetToolAnnotations,
    description:
        'Changes how apps render, to check layouts without another phone: '
        'dark mode (nightMode), text size (fontScale), screen density (dpi) '
        'and size (WIDTHxHEIGHT). Settings stay until changed; reset: true '
        'restores light mode, font scale 1.0, and the physical density and '
        'size. Returns the settings now in effect.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'nightMode': {
          'type': 'string',
          'enum': ['yes', 'no', 'auto'],
          'description': 'Dark mode on, off, or by time of day.',
        },
        'fontScale': {
          'type': 'number',
          'description': 'Text size multiplier, 0.5–3.0 (1.0 = default).',
        },
        'density': {
          'type': 'string',
          'description': 'Density in dpi, e.g. "320", or "reset".',
        },
        'size': {
          'type': 'string',
          'description': 'Screen size, e.g. "1080x1920", or "reset".',
        },
        'reset': {
          'type': 'boolean',
          'description': 'Restore defaults before applying the rest.',
        },
        'deviceSerial': mcpDeviceSerialProp,
      },
    },
  ),
];
