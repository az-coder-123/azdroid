import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';

/// A straight finger path for `android_scroll`.
typedef McpScrollPath = ({McpPoint start, McpPoint end});

/// The finger path for scrolling content in [direction] by [distance] (a
/// fraction of the screen, clamped to 0.05–0.95), through the screen center.
///
/// The finger moves against the content: scrolling **down** (revealing lower
/// content) swipes **up**.
McpScrollPath mcpScrollPath(String direction, double distance) {
  const center = 0.5;
  const minEdge = 0.05;
  const maxEdge = 0.95;
  final half = distance.clamp(minEdge, maxEdge) / 2;
  final near = (center - half).clamp(minEdge, maxEdge);
  final far = (center + half).clamp(minEdge, maxEdge);
  return switch (direction.toLowerCase().trim()) {
    'up' => (
      start: McpPoint.ratio(center, near),
      end: McpPoint.ratio(center, far),
    ),
    'left' => (
      start: McpPoint.ratio(near, center),
      end: McpPoint.ratio(far, center),
    ),
    'right' => (
      start: McpPoint.ratio(far, center),
      end: McpPoint.ratio(near, center),
    ),
    _ => (
      start: McpPoint.ratio(center, far),
      end: McpPoint.ratio(center, near),
    ),
  };
}

/// Gesture duration for a scroll [speed] (`fast`/`fling`, `normal`,
/// `slow`/`drag`), unless an explicit positive [durationMs] is given.
int mcpScrollDurationMs(String speed, int? durationMs) {
  if (durationMs != null && durationMs > 0) return durationMs;
  return switch (speed.toLowerCase().trim()) {
    'fast' || 'fling' => 80,
    'slow' || 'drag' => 600,
    _ => 250,
  };
}
