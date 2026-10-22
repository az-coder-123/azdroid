import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_touch_timeline.dart';

/// Where touch messages go: a scrcpy control socket in production, a list
/// in tests.
typedef McpTouchSink = ({
  void Function(Uint8List message) send,
  Future<void> Function() flush,
});

/// Timing of a played gesture: how late events left the computer compared
/// with their planned time.
typedef McpTouchPlayback = ({int events, int durationMs, int maxLagMs});

/// Sends a [McpTouchTimeline] to a scrcpy control socket on schedule.
///
/// Events planned for the same millisecond go out in one write, so fingers
/// that touch together arrive together. Timing is measured on this side;
/// adb's forwarding adds a few milliseconds that are the same for every
/// event.
class McpTouchPlayer {
  const McpTouchPlayer._();

  static Future<McpTouchPlayback> play(
    List<McpTouchEvent> events, {
    required int width,
    required int height,
    required void Function(Uint8List) send,
    Future<void> Function()? flush,
  }) async {
    final clock = Stopwatch()..start();
    var maxLag = 0;
    var i = 0;
    while (i < events.length) {
      final at = events[i].atMs;
      final batch = BytesBuilder(copy: false);
      for (; i < events.length && events[i].atMs == at; i++) {
        final e = events[i];
        batch.add(
          ScrcpyControlMessage.touch(
            action: e.action,
            x: e.x,
            y: e.y,
            screenWidth: width,
            screenHeight: height,
            pointerId: e.pointerId,
            pressure: e.action == McpTouchEvent.up ? 0.0 : 1.0,
          ),
        );
      }
      final wait = at - clock.elapsedMilliseconds;
      if (wait > 0) await Future<void>.delayed(Duration(milliseconds: wait));
      final lag = clock.elapsedMilliseconds - at;
      if (lag > maxLag) maxLag = lag;
      send(batch.takeBytes());
      await flush?.call();
    }
    return (
      events: events.length,
      durationMs: clock.elapsedMilliseconds,
      maxLagMs: maxLag,
    );
  }
}
