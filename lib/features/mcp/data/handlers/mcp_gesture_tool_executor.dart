import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Handler for multi-touch gestures (pinch zoom and two-finger rotation).
class McpGestureToolExecutor {
  const McpGestureToolExecutor(this._adb);

  final McpAdbClient _adb;

  bool canHandle(String toolName) => const {
    'android_pinch_gesture',
    'android_rotate_gesture',
  }.contains(toolName);

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'android_pinch_gesture':
        final scale = arguments.getRequiredDouble(
          'scale',
          aliases: ['zoom', 'factor', 'scaleFactor', 'scale_factor'],
        );
        final cx =
            arguments.getOptionalDouble(
              'centerX',
              aliases: ['x', 'center_x', 'xRatio'],
            ) ??
            0.5;
        final cy =
            arguments.getOptionalDouble(
              'centerY',
              aliases: ['y', 'center_y', 'yRatio'],
            ) ??
            0.5;
        final dur = arguments.getInt(
          'durationMs',
          aliases: ['duration', 'timeMs'],
          defaultValue: 400,
        );
        final ok = await _adb.pinchGesture(
          serial,
          scale: scale,
          centerX: cx,
          centerY: cy,
          durationMs: dur,
        );
        return ok
            ? McpToolResult.text(
                'Injected pinch gesture (scale: $scale, center: ($cx, $cy)) on $serial.',
              )
            : McpToolResult.error('Failed to inject pinch gesture.');

      case 'android_rotate_gesture':
        final angle = arguments.getRequiredDouble(
          'angleDegrees',
          aliases: ['angle', 'degrees', 'deg', 'rotation'],
        );
        final cx =
            arguments.getOptionalDouble(
              'centerX',
              aliases: ['x', 'center_x', 'xRatio'],
            ) ??
            0.5;
        final cy =
            arguments.getOptionalDouble(
              'centerY',
              aliases: ['y', 'center_y', 'yRatio'],
            ) ??
            0.5;
        final radius =
            arguments.getOptionalDouble(
              'radius',
              aliases: ['r', 'distance', 'radiusRatio'],
            ) ??
            200.0;
        final dur = arguments.getInt(
          'durationMs',
          aliases: ['duration', 'timeMs'],
          defaultValue: 400,
        );
        final ok = await _adb.rotateGesture(
          serial,
          angleDegrees: angle,
          centerX: cx,
          centerY: cy,
          radius: radius,
          durationMs: dur,
        );
        return ok
            ? McpToolResult.text(
                'Injected rotate gesture ($angle° around ($cx, $cy)) on $serial.',
              )
            : McpToolResult.error('Failed to inject rotate gesture.');

      default:
        return McpToolResult.error('Unhandled gesture tool: $toolName');
    }
  }
}
