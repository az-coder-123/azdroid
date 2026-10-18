import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';

/// Replays a live touch stream with what `adb shell input` can do: one
/// finger becomes a tap or a swipe when it lifts. Two fingers (pinch) are
/// impossible over adb, so such a stream is rejected.
class AdbTouchStreamAdapter {
  AdbTouchStreamAdapter(this._adb);

  final ControlDatasource _adb;
  PixelPoint? _start;
  PixelPoint? _last;

  Future<bool> handle(
    String deviceSerial,
    TouchStreamPhase phase,
    List<PixelPoint> points, {
    FrameSize? frame,
  }) async {
    if (points.length > 1) {
      _start = null;
      return false;
    }
    switch (phase) {
      case TouchStreamPhase.start:
        if (points.isEmpty) return false;
        _start = _last = points.first;
        return true;
      case TouchStreamPhase.move:
        if (_start == null || points.isEmpty) return false;
        _last = points.first;
        return true;
      case TouchStreamPhase.end:
        final start = _start;
        final end = points.isEmpty ? _last : points.first;
        _start = _last = null;
        if (start == null || end == null) return false;
        return _replay(deviceSerial, start, end, frame);
    }
  }

  Future<bool> _replay(
    String deviceSerial,
    PixelPoint start,
    PixelPoint end,
    FrameSize? frame,
  ) {
    final dx = (end.x - start.x).abs();
    final dy = (end.y - start.y).abs();
    if (dx + dy < ControlConstants.minSwipeDistance) {
      return _adb.injectTap(deviceSerial, end.x, end.y, frame: frame);
    }
    return _adb.injectSwipe(
      deviceSerial,
      start.x,
      start.y,
      end.x,
      end.y,
      ControlConstants.defaultSwipeDurationMs,
      frame: frame,
    );
  }
}
