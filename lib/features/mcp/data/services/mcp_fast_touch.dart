import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_scrcpy_touch_session.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_touch_player.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_point.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_touch_timeline.dart';

/// Opens a touch sink for a device, or throws when it cannot.
typedef McpTouchSinkOpener = Future<McpTouchSink> Function(
  McpAdbClient adb,
  String serial,
);

/// Plays taps and swipes through the scrcpy touch session
/// ([McpScrcpyTouchSession]) when it can start, so they take milliseconds
/// instead of the 100–300 ms of each `adb shell input` command. Callers
/// keep adb as the fallback: [play] returns `false` when the session is
/// unavailable.
class McpFastTouch {
  const McpFastTouch._();

  /// Press time of a tap; Android treats a press shorter than its tap
  /// timeout (100 ms) as a tap.
  static const int tapHoldMs = 40;

  /// After a failed start, adb is used without retrying for this long, so a
  /// device or computer without scrcpy does not pay the start-up time on
  /// every call.
  static const Duration retryAfter = Duration(minutes: 1);

  /// How the session is opened; tests replace it.
  static McpTouchSinkOpener opener = _openScrcpy;

  static final Map<String, DateTime> _unavailableUntil = {};

  /// Clears remembered failures (tests, or after the device changed).
  static void reset() => _unavailableUntil.clear();

  /// Plays [strokes] on [serial]; `false` when the session is unavailable
  /// and nothing was sent, so the caller should use adb.
  static Future<bool> play(
    McpAdbClient adb,
    String serial,
    List<McpTouchStroke> strokes,
  ) async {
    final until = _unavailableUntil[serial];
    if (until != null && DateTime.now().isBefore(until)) return false;
    final McpTouchSink sink;
    try {
      sink = await opener(adb, serial);
    } on Object {
      // Any start failure (no jar, server refused, no adb) means adb input.
      _unavailableUntil[serial] = DateTime.now().add(retryAfter);
      return false;
    }
    final size = await adb.getDisplaySize(serial);
    await McpTouchPlayer.play(
      McpTouchTimeline.compile(strokes, size.x, size.y),
      width: size.x,
      height: size.y,
      send: sink.send,
      flush: sink.flush,
    );
    return true;
  }

  /// One finger pressing [x], [y] for [holdMs], starting at [atMs].
  static McpTouchStroke tap(
    int x,
    int y, {
    int atMs = 0,
    int holdMs = tapHoldMs,
  }) => McpTouchStroke([
    (point: McpPoint.pixels(x, y), atMs: atMs),
  ], holdMs: holdMs);

  /// One finger moving from start to end over [durationMs] (a fling, a
  /// drag, or, without movement, a long press).
  static McpTouchStroke swipe(
    (int, int) start,
    (int, int) end,
    int durationMs,
  ) => McpTouchStroke([
    (point: McpPoint.pixels(start.$1, start.$2), atMs: 0),
    (point: McpPoint.pixels(end.$1, end.$2), atMs: durationMs),
  ]);

  static Future<McpTouchSink> _openScrcpy(
    McpAdbClient adb,
    String serial,
  ) async {
    final session = await McpScrcpyTouchSession.open(adb, serial);
    return (send: session.send, flush: session.flush);
  }
}
