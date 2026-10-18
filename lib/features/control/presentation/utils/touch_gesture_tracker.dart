import 'dart:math' as math;

import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:flutter/painting.dart';

/// Receives each step of a live touch stream, in normalized coordinates.
typedef TouchStreamSink = void Function(
  TouchStreamPhase phase,
  List<NormalizedPoint> points,
);

/// Turns desktop gestures into live Android fingers.
///
/// - Trackpad two-finger pan: one finger that follows the pan, so lists
///   scroll and fling as they do on the phone.
/// - Trackpad pinch or rotate: two fingers around the pointer, apart by
///   [ControlConstants.pinchInitialSpanFraction] × scale, turned by the
///   rotation.
/// - Alt-drag with a mouse: two fingers, the second mirrored through the
///   screen center (scrcpy's Ctrl-drag), for pinch and rotate without a
///   trackpad.
///
/// Nothing reaches the phone until the gesture's intent is clear, and the
/// finger count stays fixed until the gesture ends.
class TouchGestureTracker {
  TouchGestureTracker(this._sink);

  final TouchStreamSink _sink;
  _Mode _mode = _Mode.idle;
  Offset _origin = Offset.zero;
  Size _viewport = Size.zero;
  List<NormalizedPoint> _last = const [];

  /// Whether a gesture is in progress (its pointer events are taken).
  bool get isActive => _mode != _Mode.idle;

  /// Whether a mouse Alt-drag pinch is in progress.
  bool get isMirroring => _mode == _Mode.mirrored;

  void panZoomStart(Offset position, Size viewport) {
    _cancelIfActive();
    _origin = position;
    _viewport = viewport;
    _mode = _Mode.undecided;
  }

  /// [pan] is the total pan since the start, in logical pixels.
  void panZoomUpdate({
    required Offset pan,
    required double scale,
    required double rotation,
  }) {
    switch (_mode) {
      case _Mode.undecided:
        if ((scale - 1).abs() > ControlConstants.pinchScaleThreshold ||
            rotation.abs() > ControlConstants.pinchRotationThreshold) {
          _mode = _Mode.pinch;
          _emit(TouchStreamPhase.start, _pinch(pan, scale, rotation));
        } else if (pan.distance > ControlConstants.panStartDistance) {
          _mode = _Mode.drag;
          _emit(TouchStreamPhase.start, [_normalize(_origin)]);
          _emit(TouchStreamPhase.move, [_normalize(_origin + pan)]);
        }
      case _Mode.pinch:
        _emit(TouchStreamPhase.move, _pinch(pan, scale, rotation));
      case _Mode.drag:
        _emit(TouchStreamPhase.move, [_normalize(_origin + pan)]);
      case _Mode.idle || _Mode.mirrored:
        break;
    }
  }

  void panZoomEnd() => _finish();

  void mirroredStart(Offset position, Size viewport) {
    _cancelIfActive();
    _viewport = viewport;
    _mode = _Mode.mirrored;
    _emit(TouchStreamPhase.start, _mirrored(position));
  }

  void mirroredMove(Offset position) {
    if (_mode == _Mode.mirrored) {
      _emit(TouchStreamPhase.move, _mirrored(position));
    }
  }

  void mirroredEnd() => _finish();

  void _finish() {
    final started = _mode != _Mode.idle && _mode != _Mode.undecided;
    if (started) _emit(TouchStreamPhase.end, _last);
    _mode = _Mode.idle;
    _last = const [];
  }

  /// A new gesture never overlaps the previous one on the phone.
  void _cancelIfActive() {
    if (isActive) _finish();
  }

  List<NormalizedPoint> _pinch(Offset pan, double scale, double rotation) {
    final center = _origin + pan;
    final halfSpan =
        _viewport.shortestSide *
        ControlConstants.pinchInitialSpanFraction /
        2 *
        scale;
    final offset = Offset(math.cos(rotation), math.sin(rotation)) * halfSpan;
    return [_normalize(center + offset), _normalize(center - offset)];
  }

  List<NormalizedPoint> _mirrored(Offset position) => [
    _normalize(position),
    _normalize(Offset(_viewport.width, _viewport.height) - position),
  ];

  NormalizedPoint _normalize(Offset position) {
    if (_viewport.isEmpty) return const NormalizedPoint(0, 0);
    return NormalizedPoint(
      position.dx / _viewport.width,
      position.dy / _viewport.height,
    ).clamped();
  }

  void _emit(TouchStreamPhase phase, List<NormalizedPoint> points) {
    _last = points;
    _sink(phase, points);
  }
}

enum _Mode { idle, undecided, drag, pinch, mirrored }
