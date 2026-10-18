import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';

/// Sends input through the scrcpy control socket when it is available for
/// the device, and through adb otherwise (no active mirroring session, size
/// unknown, socket closed, or text input).
class FallbackControlDatasource implements ControlDatasource {
  FallbackControlDatasource({required this._primary, required this._fallback});

  final ScrcpyControlDatasource _primary;
  final ControlDatasource _fallback;

  /// Where the current touch stream goes, decided at its start so its
  /// events never split between the two paths.
  bool _streamOnFallback = false;

  @override
  Future<bool> injectTouchStream(
    String deviceSerial,
    TouchStreamPhase phase,
    List<PixelPoint> points, {
    FrameSize? frame,
  }) async {
    if (phase == TouchStreamPhase.start) {
      _streamOnFallback = !await _primary.injectTouchStream(
        deviceSerial,
        phase,
        points,
        frame: frame,
      );
      if (!_streamOnFallback) return true;
    }
    final target = _streamOnFallback ? _fallback : _primary;
    return target.injectTouchStream(deviceSerial, phase, points, frame: frame);
  }

  @override
  Future<bool> injectTap(
    String deviceSerial,
    int x,
    int y, {
    FrameSize? frame,
  }) async =>
      await _primary.injectTap(deviceSerial, x, y, frame: frame) ||
      await _fallback.injectTap(deviceSerial, x, y, frame: frame);

  @override
  Future<bool> injectSwipe(
    String deviceSerial,
    int startX,
    int startY,
    int endX,
    int endY,
    int durationMs, {
    FrameSize? frame,
  }) async =>
      await _primary.injectSwipe(
        deviceSerial,
        startX,
        startY,
        endX,
        endY,
        durationMs,
        frame: frame,
      ) ||
      await _fallback.injectSwipe(
        deviceSerial,
        startX,
        startY,
        endX,
        endY,
        durationMs,
        frame: frame,
      );

  @override
  Future<bool> injectKeyevent(String deviceSerial, int keyCode) async =>
      await _primary.injectKeyevent(deviceSerial, keyCode) ||
      await _fallback.injectKeyevent(deviceSerial, keyCode);

  @override
  Future<bool> injectText(String deviceSerial, String text) async =>
      await _primary.injectText(deviceSerial, text) ||
      await _fallback.injectText(deviceSerial, text);
}
