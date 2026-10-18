import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';

/// Sends input through the scrcpy control socket when it is available for
/// the device, and through adb otherwise (no active mirroring session, size
/// unknown, socket closed, or text input).
class FallbackControlDatasource implements ControlDatasource {
  const FallbackControlDatasource({
    required this._primary,
    required this._fallback,
  });

  final ScrcpyControlDatasource _primary;
  final ControlDatasource _fallback;

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
