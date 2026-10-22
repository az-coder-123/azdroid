import 'dart:math';

import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_touch_timeline.dart';

/// Two-finger gestures as strokes, for the scrcpy touch session.
class McpGestureStrokes {
  const McpGestureStrokes._();

  /// Points per finger along a gesture; the timeline fills in moves.
  static const int segments = 12;

  /// Two fingers on a diagonal through [center] whose distance grows (zoom
  /// in, [scale] > 1) or shrinks from [baseSpan] pixels.
  static List<McpTouchStroke> pinch({
    required (int, int) center,
    required double scale,
    required int durationMs,
    double baseSpan = 300,
  }) {
    final s = scale.clamp(0.1, 4.0);
    final (from, to) = s >= 1
        ? (baseSpan, baseSpan * s)
        : (baseSpan / s, baseSpan);
    List<({McpPoint point, int atMs})> finger(int sign) => [
      for (var i = 0; i <= segments; i++)
        () {
          final half = (from + (to - from) * i / segments) / 2 / sqrt2;
          return (
            point: McpPoint.pixels(
              center.$1 + sign * half,
              center.$2 + sign * half,
            ),
            atMs: durationMs * i ~/ segments,
          );
        }(),
    ];
    return [McpTouchStroke(finger(-1)), McpTouchStroke(finger(1))];
  }

  /// Two fingers opposite each other on a circle of [radius] pixels around
  /// [center], turning by [angleDegrees] (positive = clockwise on screen).
  static List<McpTouchStroke> rotate({
    required (int, int) center,
    required double angleDegrees,
    required double radius,
    required int durationMs,
  }) {
    final sweep = angleDegrees * pi / 180;
    List<({McpPoint point, int atMs})> finger(double start) => [
      for (var i = 0; i <= segments; i++)
        (
          point: McpPoint.pixels(
            center.$1 + radius * cos(start + sweep * i / segments),
            center.$2 + radius * sin(start + sweep * i / segments),
          ),
          atMs: durationMs * i ~/ segments,
        ),
    ];
    return [McpTouchStroke(finger(0)), McpTouchStroke(finger(pi))];
  }
}
