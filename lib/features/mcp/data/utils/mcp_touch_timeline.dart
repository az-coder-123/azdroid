import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point_arguments.dart';
import 'package:equatable/equatable.dart';

/// One finger's path: it touches down at the first point's time, moves
/// through the points, and lifts at the last one. A single point is a tap
/// held for [holdMs].
class McpTouchStroke extends Equatable {
  const McpTouchStroke(this.points, {this.holdMs = defaultHoldMs});

  static const int defaultHoldMs = 50;

  final List<({McpPoint point, int atMs})> points;
  final int holdMs;

  @override
  List<Object?> get props => [points, holdMs];
}

/// A touch event at [atMs] after the gesture starts, in screen pixels.
/// [pointerId] tells fingers apart; [action] is Android's MotionEvent
/// DOWN (0), UP (1), or MOVE (2).
class McpTouchEvent extends Equatable {
  const McpTouchEvent(this.atMs, this.pointerId, this.action, this.x, this.y);

  static const int down = 0;
  static const int up = 1;
  static const int move = 2;

  final int atMs;
  final int pointerId;
  final int action;
  final int x;
  final int y;

  @override
  List<Object?> get props => [atMs, pointerId, action, x, y];
}

/// Turns strokes into a time-ordered list of touch events, so several
/// fingers can move at once with millisecond timing (a joystick held while
/// another finger taps).
class McpTouchTimeline {
  const McpTouchTimeline._();

  /// Interval between MOVE events while a finger travels (125 Hz).
  static const int sampleMs = 8;

  /// Android's scrcpy server tracks at most 10 pointers.
  static const int maxFingers = 10;
  static const int maxDurationMs = 60000;

  /// Strokes from tool arguments: `[{points: [{x, y, t}, …], holdMs}]`.
  /// Each point takes the coordinate forms of every touch tool (`x`/`y`,
  /// `xRatio`, `xPixel`); `t` is milliseconds from the gesture start.
  static List<McpTouchStroke> parse(Object? raw) {
    if (raw is! List || raw.isEmpty) {
      throw const McpArgumentException(
        'strokes must be a non-empty list of {points: [{x, y, t}]}.',
      );
    }
    return [
      for (final (i, stroke) in raw.indexed)
        if (stroke case final Map<String, dynamic> s)
          _stroke(i, s)
        else
          throw McpArgumentException('strokes[$i] must be an object.'),
    ];
  }

  static McpTouchStroke _stroke(int i, Map<String, dynamic> s) {
    final raw = s['points'];
    if (raw is! List || raw.isEmpty) {
      throw McpArgumentException(
        'strokes[$i].points must be a non-empty list.',
      );
    }
    var last = -1;
    final points = <({McpPoint point, int atMs})>[];
    for (final (j, p) in raw.indexed) {
      if (p is! Map<String, dynamic>) {
        throw McpArgumentException('strokes[$i].points[$j] must be an object.');
      }
      final t = p.getInt('t', aliases: ['atMs', 'timeMs'], defaultValue: 0);
      if (t < last) {
        throw McpArgumentException(
          'strokes[$i].points[$j].t ($t) is earlier than the point before it.',
        );
      }
      last = t;
      points.add((point: p.getPoint(), atMs: t));
    }
    return McpTouchStroke(
      points,
      holdMs: s.getInt('holdMs', defaultValue: McpTouchStroke.defaultHoldMs),
    );
  }

  /// Events for a [width] × [height] screen (the current orientation),
  /// ordered by time. Throws when more than [maxFingers] fingers touch at
  /// once or the gesture is longer than [maxDurationMs].
  static List<McpTouchEvent> compile(
    List<McpTouchStroke> strokes,
    int width,
    int height,
  ) {
    final events = <(int seq, McpTouchEvent event)>[];
    void add(int id, int at, int action, (int, int) xy) => events.add((
      events.length,
      McpTouchEvent(at, id, action, xy.$1, xy.$2),
    ));

    for (final (id, stroke) in strokes.indexed) {
      final pts = [
        for (final p in stroke.points)
          (at: p.atMs, xy: p.point.toPixels(width, height)),
      ];
      add(id, pts.first.at, McpTouchEvent.down, pts.first.xy);
      if (pts.length == 1) {
        add(id, pts.first.at + stroke.holdMs, McpTouchEvent.up, pts.first.xy);
        continue;
      }
      for (var k = 1; k < pts.length; k++) {
        final (a, b) = (pts[k - 1], pts[k]);
        final span = b.at - a.at;
        for (var t = sampleMs; t < span; t += sampleMs) {
          final f = t / span;
          add(id, a.at + t, McpTouchEvent.move, (
            (a.xy.$1 + (b.xy.$1 - a.xy.$1) * f).round(),
            (a.xy.$2 + (b.xy.$2 - a.xy.$2) * f).round(),
          ));
        }
        add(id, b.at, McpTouchEvent.move, b.xy);
      }
      add(id, pts.last.at, McpTouchEvent.up, pts.last.xy);
    }

    // By time; at equal times, in creation order (a finger's DOWN before
    // its UP). List.sort is not stable, hence the sequence number.
    events.sort(
      (a, b) => a.$2.atMs != b.$2.atMs
          ? a.$2.atMs.compareTo(b.$2.atMs)
          : a.$1.compareTo(b.$1),
    );
    final ordered = [for (final e in events) e.$2];
    _check(ordered);
    return ordered;
  }

  static void _check(List<McpTouchEvent> events) {
    if (events.isNotEmpty && events.last.atMs > maxDurationMs) {
      throw McpArgumentException(
        'The gesture lasts ${events.last.atMs} ms; the limit is '
        '$maxDurationMs ms.',
      );
    }
    final down = <int>{};
    for (final e in events) {
      if (e.action == McpTouchEvent.down) down.add(e.pointerId);
      if (down.length > maxFingers) {
        throw McpArgumentException(
          'More than $maxFingers fingers touch at ${e.atMs} ms.',
        );
      }
      if (e.action == McpTouchEvent.up) down.remove(e.pointerId);
    }
  }
}
