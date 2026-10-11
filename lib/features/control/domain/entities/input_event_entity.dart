import 'package:equatable/equatable.dart';

/// Supported types of input actions forwarded to the Android device.
enum InputEventType {
  pointerDown,
  pointerMove,
  pointerUp,
  scroll,
  keyDown,
  keyUp,
}

/// Normalized input event entity representing mouse, touch, or keyboard actions.
class InputEventEntity extends Equatable {
  const InputEventEntity({
    required this.type,
    this.normalizedX = 0.0,
    this.normalizedY = 0.0,
    this.keyCode,
    this.button,
    this.scrollDeltaX = 0.0,
    this.scrollDeltaY = 0.0,
  });

  /// Action classification.
  final InputEventType type;

  /// Horizontal position normalized across the display ($0.0 \to 1.0$).
  final double normalizedX;

  /// Vertical position normalized across the display ($0.0 \to 1.0$).
  final double normalizedY;

  /// Linux/Android physical keycode.
  final int? keyCode;

  /// Mouse button index (e.g., 0 for left, 1 for right, 2 for middle).
  final int? button;

  /// Horizontal scroll wheel offset.
  final double scrollDeltaX;

  /// Vertical scroll wheel offset.
  final double scrollDeltaY;

  @override
  List<Object?> get props => [
    type,
    normalizedX,
    normalizedY,
    keyCode,
    button,
    scrollDeltaX,
    scrollDeltaY,
  ];
}
