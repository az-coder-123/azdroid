import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/scrcpy_control_message.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';

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

  /// Text with characters outside ASCII (Vietnamese accents, CJK, emoji)
  /// is put on the device clipboard and pasted by the server: key-map
  /// typing (`input text`, scrcpy INJECT_TEXT) cannot produce them, and an
  /// IME such as Telex would rewrite them. Pure ASCII returns `false`, so
  /// the adb path types it without touching the device clipboard.
  @override
  Future<bool> injectText(String deviceSerial, String text) async {
    if (text.isEmpty || _isAscii(text) || !isAvailableFor(deviceSerial)) {
      return false;
    }
    return _channel.send(
      ScrcpyControlMessage.setClipboard(text: text, paste: true),
    );
  }

  /// One scrcpy pointer id per finger: the mouse finger, then the
  /// simulated second finger.
  static const List<int> _pointerIds = [
    ScrcpyControlMessage.pointerIdGenericFinger,
    ScrcpyControlMessage.pointerIdVirtualFinger,
  ];

  List<PixelPoint> _streamPoints = const [];

  @override
  Future<bool> injectTouchStream(
    String deviceSerial,
    TouchStreamPhase phase,
    List<PixelPoint> points, {
    FrameSize? frame,
  }) async {
    if (frame == null || !isAvailableFor(deviceSerial)) return false;
    final fingers = points.isEmpty ? _streamPoints : points;
    if (fingers.isEmpty || fingers.length > _pointerIds.length) return false;
    final action = switch (phase) {
      TouchStreamPhase.start => ScrcpyControlMessage.actionDown,
      TouchStreamPhase.move => ScrcpyControlMessage.actionMove,
      TouchStreamPhase.end => ScrcpyControlMessage.actionUp,
    };
    // The server turns the second DOWN/UP into POINTER_DOWN/POINTER_UP.
    for (var i = 0; i < fingers.length; i++) {
      final finger = fingers[i];
      final sent = _send(
        _touch(action, finger.x, finger.y, frame, pointerId: _pointerIds[i]),
      );
      if (!sent) return false;
    }
    _streamPoints = phase == TouchStreamPhase.end ? const [] : fingers;
    return true;
  }

  static bool _isAscii(String text) =>
      text.codeUnits.every((unit) => unit < _firstNonAsciiCodeUnit);

  static const int _firstNonAsciiCodeUnit = 0x80;

  Uint8List _touch(
    int action,
    int x,
    int y,
    FrameSize frame, {
    int pointerId = ScrcpyControlMessage.pointerIdGenericFinger,
  }) => ScrcpyControlMessage.touch(
    action: action,
    x: x,
    y: y,
    screenWidth: frame.width,
    screenHeight: frame.height,
    pointerId: pointerId,
    pressure: action == ScrcpyControlMessage.actionUp ? 0 : 1,
  );

  bool _send(Uint8List message) => _channel.send(message);
}
