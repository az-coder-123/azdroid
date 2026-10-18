import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/scrcpy/scrcpy_control_message.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';

/// [ControlDatasource] over the scrcpy control socket: no process per event,
/// so taps and swipes reach the device in milliseconds.
///
/// Positional events need the exact video [FrameSize]; without it (or without
/// a connected channel for the device) every method returns `false` so the
/// caller can fall back to adb.
class ScrcpyControlDatasource implements ControlDatasource {
  ScrcpyControlDatasource({
    required this._channel,
    this.moveInterval = const Duration(milliseconds: 16),
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  final ScrcpyControlChannel _channel;

  /// Time between MOVE events of a swipe (about one 60 Hz frame).
  final Duration moveInterval;
  final Future<void> Function(Duration) _delay;

  /// Whether input for [deviceSerial] can go through the control socket.
  bool isAvailableFor(String deviceSerial) =>
      _channel.isConnected && _channel.deviceSerial == deviceSerial;

  @override
  Future<bool> injectTap(
    String deviceSerial,
    int x,
    int y, {
    FrameSize? frame,
  }) async {
    if (frame == null || !isAvailableFor(deviceSerial)) return false;
    return _send(_touch(ScrcpyControlMessage.actionDown, x, y, frame)) &&
        _send(_touch(ScrcpyControlMessage.actionUp, x, y, frame));
  }

  @override
  Future<bool> injectSwipe(
    String deviceSerial,
    int startX,
    int startY,
    int endX,
    int endY,
    int durationMs, {
    FrameSize? frame,
  }) async {
    if (frame == null || !isAvailableFor(deviceSerial)) return false;
    if (!_send(
      _touch(ScrcpyControlMessage.actionDown, startX, startY, frame),
    )) {
      return false;
    }
    final steps = (durationMs ~/ moveInterval.inMilliseconds).clamp(1, 1000);
    for (var step = 1; step <= steps; step++) {
      await _delay(moveInterval);
      final t = step / steps;
      final x = (startX + (endX - startX) * t).round();
      final y = (startY + (endY - startY) * t).round();
      if (!_send(_touch(ScrcpyControlMessage.actionMove, x, y, frame))) {
        return false;
      }
    }
    return _send(_touch(ScrcpyControlMessage.actionUp, endX, endY, frame));
  }

  @override
  Future<bool> injectKeyevent(String deviceSerial, int keyCode) async {
    if (!isAvailableFor(deviceSerial)) return false;
    return _send(
          ScrcpyControlMessage.keycode(
            action: ScrcpyControlMessage.actionDown,
            keyCode: keyCode,
          ),
        ) &&
        _send(
          ScrcpyControlMessage.keycode(
            action: ScrcpyControlMessage.actionUp,
            keyCode: keyCode,
          ),
        );
  }

  /// Text stays on the adb path: the scrcpy server types through the device
  /// key map, which cannot produce most non-ASCII characters (for example
  /// Vietnamese). Returning `false` hands it to the fallback.
  @override
  Future<bool> injectText(String deviceSerial, String text) async => false;

  Uint8List _touch(int action, int x, int y, FrameSize frame) =>
      ScrcpyControlMessage.touch(
        action: action,
        x: x,
        y: y,
        screenWidth: frame.width,
        screenHeight: frame.height,
        pressure: action == ScrcpyControlMessage.actionUp ? 0 : 1,
      );

  bool _send(Uint8List message) => _channel.send(message);
}
