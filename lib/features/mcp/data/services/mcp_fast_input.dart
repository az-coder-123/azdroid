import 'package:desk_droid/core/services/scrcpy_control_message.dart';
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

/// Sends touches and keys through the scrcpy control session
/// ([McpScrcpyTouchSession]) when it can start, so they take milliseconds
/// instead of the 0.1–1 s of each `adb shell input` command. Callers keep
/// adb as the fallback: [play] and [pressKey] return `false` when the
/// session is unavailable.
class McpFastInput {
  const McpFastInput._();

  /// Press time of a tap; Android treats a press shorter than its tap
  /// timeout (100 ms) as a tap.
  static const int tapHoldMs = 40;

  /// After a failed start, adb is used without retrying for this long, so a
  /// device or computer without scrcpy does not pay the start-up time on
  /// every call.
  static const Duration retryAfter = Duration(minutes: 1);

  /// Minimum time between the end of one input and the start of the next.
  ///
  /// A key sent within a few milliseconds of a tap that opens a screen is
  /// lost: the app performs the click after the key (measured on Android
  /// 13: BACK 0 ms after the tap was lost, 100 ms or later always worked).
  /// `adb shell input` never hit this because each command takes about
  /// 100 ms to start.
  static const Duration minGap = Duration(milliseconds: 120);

  static final Map<String, Stopwatch> _sinceLastInput = {};

  /// How the session is opened; tests replace it.
  static McpTouchSinkOpener opener = _openScrcpy;

  static final Map<String, DateTime> _unavailableUntil = {};

  /// Clears remembered failures (tests, or after the device changed).
  static void reset() {
    _unavailableUntil.clear();
    _sinceLastInput.clear();
  }

  /// Whether input for [serial] can go through the session (starting it if
  /// needed). Batches use it to choose between per-step injection and one
  /// compound adb script.
  static Future<bool> isAvailable(McpAdbClient adb, String serial) async =>
      await _sink(adb, serial) != null;

  /// Plays [strokes] on [serial]; `false` when the session is unavailable
  /// and nothing was sent, so the caller should use adb.
  static Future<bool> play(
    McpAdbClient adb,
    String serial,
    List<McpTouchStroke> strokes,
  ) async {
    final sink = await _sink(adb, serial);
    if (sink == null) return false;
    final size = await adb.getDisplaySize(serial);
    await beforeInput(serial);
    await McpTouchPlayer.play(
      McpTouchTimeline.compile(strokes, size.x, size.y),
      width: size.x,
      height: size.y,
      send: sink.send,
      flush: sink.flush,
    );
    afterInput(serial);
    return true;
  }

  /// Waits until [minGap] has passed since the last input to [serial].
  static Future<void> beforeInput(String serial) async {
    final elapsed = _sinceLastInput[serial]?.elapsed;
    if (elapsed != null && elapsed < minGap) {
      await Future<void>.delayed(minGap - elapsed);
    }
  }

  /// Records that an input to [serial] just finished.
  static void afterInput(String serial) =>
      _sinceLastInput[serial] = Stopwatch()..start();

  /// Presses and releases Android key [keyCode]; `false` when the session
  /// is unavailable, so the caller should use `input keyevent`.
  static Future<bool> pressKey(
    McpAdbClient adb,
    String serial,
    int keyCode,
  ) async {
    final sink = await _sink(adb, serial);
    if (sink == null) return false;
    await beforeInput(serial);
    for (final action in [
      ScrcpyControlMessage.actionDown,
      ScrcpyControlMessage.actionUp,
    ]) {
      sink.send(ScrcpyControlMessage.keycode(action: action, keyCode: keyCode));
    }
    await sink.flush();
    afterInput(serial);
    return true;
  }

  static Future<McpTouchSink?> _sink(McpAdbClient adb, String serial) async {
    final until = _unavailableUntil[serial];
    if (until != null && DateTime.now().isBefore(until)) return null;
    try {
      return await opener(adb, serial);
    } on Object {
      // Any start failure (no jar, server refused, no adb) means adb input.
      _unavailableUntil[serial] = DateTime.now().add(retryAfter);
      return null;
    }
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
