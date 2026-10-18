import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:equatable/equatable.dart';

/// Base class for all remote control input injection events.
sealed class ControlEvent extends Equatable {
  const ControlEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when a touch tap occurs at normalized coordinates.
class ControlTapDispatched extends ControlEvent {
  const ControlTapDispatched({
    required this.deviceSerial,
    required this.normalizedX,
    required this.normalizedY,
  });

  final String deviceSerial;
  final double normalizedX;
  final double normalizedY;

  @override
  List<Object?> get props => [deviceSerial, normalizedX, normalizedY];
}

/// Dispatched when a touch drag/swipe gesture completes.
class ControlSwipeDispatched extends ControlEvent {
  const ControlSwipeDispatched({
    required this.deviceSerial,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.durationMs,
  });

  final String deviceSerial;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final int? durationMs;

  @override
  List<Object?> get props => [
    deviceSerial,
    startX,
    startY,
    endX,
    endY,
    durationMs,
  ];
}

/// Dispatched when mouse wheel or trackpad scroll delta is detected.
class ControlScrollDispatched extends ControlEvent {
  const ControlScrollDispatched({
    required this.deviceSerial,
    required this.normalizedX,
    required this.normalizedY,
    required this.deltaX,
    required this.deltaY,
  });

  final String deviceSerial;
  final double normalizedX;
  final double normalizedY;
  final double deltaX;
  final double deltaY;

  @override
  List<Object?> get props => [
    deviceSerial,
    normalizedX,
    normalizedY,
    deltaX,
    deltaY,
  ];
}

/// Dispatched when a physical or logical keyboard key is pressed.
class ControlKeyDispatched extends ControlEvent {
  const ControlKeyDispatched({
    required this.deviceSerial,
    required this.keyCode,
  });

  final String deviceSerial;
  final int keyCode;

  @override
  List<Object?> get props => [deviceSerial, keyCode];
}

/// Dispatched when international Unicode text is submitted for injection.
class ControlTextDispatched extends ControlEvent {
  const ControlTextDispatched({required this.deviceSerial, required this.text});

  final String deviceSerial;
  final String text;

  @override
  List<Object?> get props => [deviceSerial, text];
}

/// Dispatched when a standard Android navigation action is triggered.
class ControlNavigationActionDispatched extends ControlEvent {
  const ControlNavigationActionDispatched({
    required this.deviceSerial,
    required this.action,
  });

  final String deviceSerial;
  final NavigationAction action;

  @override
  List<Object?> get props => [deviceSerial, action];
}

/// One step of a live touch stream (trackpad drag, pinch, Alt+drag).
class ControlTouchStreamed extends ControlEvent {
  const ControlTouchStreamed({
    required this.deviceSerial,
    required this.phase,
    required this.points,
  });

  final String deviceSerial;
  final TouchStreamPhase phase;
  final List<NormalizedPoint> points;

  @override
  List<Object?> get props => [deviceSerial, phase, points];
}

/// Toggles keyboard focus capture state.
class ControlKeyboardCaptureToggled extends ControlEvent {
  const ControlKeyboardCaptureToggled({required this.isCaptured});

  final bool isCaptured;

  @override
  List<Object?> get props => [isCaptured];
}
