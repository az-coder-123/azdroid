import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_fast_input.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_touch_player.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_gesture_strokes.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_touch_timeline.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';

/// Multi-finger touch: timed strokes (games), pinch, and rotation.
///
/// All of them go through the MCP process's own scrcpy control session
/// ([McpScrcpyTouchSession]), which injects real simultaneous fingers.
/// Pinch and rotation fall back to one-finger adb approximations when the
/// session cannot start; strokes have no fallback, since adb cannot hold
/// two fingers or keep their timing.
class McpGestureToolExecutor {
  McpGestureToolExecutor(
    this._adb, {
    Future<McpTouchSink> Function(String)? openSession,
  }) : _openSession =
           openSession ?? ((serial) => McpFastInput.opener(_adb, serial));

  final McpAdbClient _adb;
  final Future<McpTouchSink> Function(String serial) _openSession;

  bool canHandle(String toolName) => const {
    'android_pinch_gesture',
    'android_rotate_gesture',
    'android_touch_strokes',
  }.contains(toolName);

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    final size = await _adb.getDisplaySize(serial);
    (int, int) center() => McpPoint(
      McpAxis(
        arguments.getOptionalDouble('centerX', aliases: ['x', 'xRatio']) ?? 0.5,
        McpUnit.auto,
      ),
      McpAxis(
        arguments.getOptionalDouble('centerY', aliases: ['y', 'yRatio']) ?? 0.5,
        McpUnit.auto,
      ),
    ).toPixels(size.x, size.y);
    final durationMs = arguments.getInt(
      'durationMs',
      aliases: ['duration', 'timeMs'],
      defaultValue: 400,
    );

    switch (toolName) {
      case 'android_touch_strokes':
        final strokes = McpTouchTimeline.parse(arguments['strokes']);
        final result = await _play(serial, strokes, size.x, size.y);
        return McpToolResult.text(
          'Played ${strokes.length} stroke(s) as ${result.events} touch '
          'events over ${result.durationMs} ms on $serial (screen '
          '${size.x}×${size.y}; latest event ${result.maxLagMs} ms behind '
          'schedule).',
        );

      case 'android_pinch_gesture':
        final scale = arguments.getRequiredDouble(
          'scale',
          aliases: ['zoom', 'factor', 'scaleFactor', 'scale_factor'],
        );
        final strokes = McpGestureStrokes.pinch(
          center: center(),
          scale: scale,
          durationMs: durationMs,
        );
        return _twoFingers(
          serial,
          strokes,
          size.x,
          size.y,
          'pinch (scale $scale)',
          () => _adb.pinchGesture(
            serial,
            scale: scale,
            centerX: center().$1.toDouble(),
            centerY: center().$2.toDouble(),
            durationMs: durationMs,
          ),
        );

      case 'android_rotate_gesture':
        final angle = arguments.getRequiredDouble(
          'angleDegrees',
          aliases: ['angle', 'degrees', 'deg', 'rotation'],
        );
        final r = arguments.getOptionalDouble('radius', aliases: ['r']) ?? 200;
        final radius = r <= 1 ? r * size.x : r;
        final strokes = McpGestureStrokes.rotate(
          center: center(),
          angleDegrees: angle,
          radius: radius,
          durationMs: durationMs,
        );
        return _twoFingers(
          serial,
          strokes,
          size.x,
          size.y,
          'rotation ($angle°)',
          () => _adb.rotateGesture(
            serial,
            angleDegrees: angle,
            centerX: center().$1.toDouble(),
            centerY: center().$2.toDouble(),
            radius: radius,
            durationMs: durationMs,
          ),
        );

      default:
        return McpToolResult.error('Unhandled gesture tool: $toolName');
    }
  }

  Future<McpToolResult> _twoFingers(
    String serial,
    List<McpTouchStroke> strokes,
    int width,
    int height,
    String label,
    Future<bool> Function() fallback,
  ) async {
    try {
      final r = await _play(serial, strokes, width, height);
      return McpToolResult.text(
        'Two-finger $label on $serial over ${r.durationMs} ms (scrcpy).',
      );
    } on McpUnsupportedOnDeviceException catch (e) {
      final ok = await fallback();
      return ok
          ? McpToolResult.text(
              'One-finger approximation of $label on $serial; real two-finger '
              'touch was unavailable: ${e.message}',
            )
          : McpToolResult.error('Failed to inject $label: ${e.message}');
    }
  }

  Future<McpTouchPlayback> _play(
    String serial,
    List<McpTouchStroke> strokes,
    int width,
    int height,
  ) async {
    final events = McpTouchTimeline.compile(strokes, width, height);
    final sink = await _openSession(serial);
    await McpFastInput.beforeInput(serial);
    final played = await McpTouchPlayer.play(
      events,
      width: width,
      height: height,
      send: sink.send,
      flush: sink.flush,
    );
    McpFastInput.afterInput(serial);
    return played;
  }
}
