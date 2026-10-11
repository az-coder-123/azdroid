import 'package:equatable/equatable.dart';

/// Supported types of input actions forwarded to the Android device.
enum InputEventType {
  pointerDown,
  pointerMove,
  pointerUp,
  tap,
  swipe,
  scroll,
  keyDown,
  keyUp,
  text,
  shortcut,
}

/// Navigation shortcut actions supported by Android.
enum NavigationAction { back, home, appSwitch, volumeUp, volumeDown, power }

/// Normalized input event entity representing mouse, touch, or keyboard actions.
class InputEventEntity extends Equatable {
  const InputEventEntity({
    required this.type,
    this.normalizedX = 0.0,
    this.normalizedY = 0.0,
    this.normalizedEndX = 0.0,
    this.normalizedEndY = 0.0,
    this.keyCode,
    this.button,
    this.scrollDeltaX = 0.0,
    this.scrollDeltaY = 0.0,
    this.text,
    this.durationMs,
    this.navigationAction,
  });

  /// Action classification.
  final InputEventType type;

  /// Primary horizontal position normalized across the display (0.0 to 1.0).
  final double normalizedX;

  /// Primary vertical position normalized across the display (0.0 to 1.0).
  final double normalizedY;

  /// Secondary/destination horizontal position normalized (for swipe gestures).
  final double normalizedEndX;

  /// Secondary/destination vertical position normalized (for swipe gestures).
  final double normalizedEndY;

  /// Linux/Android physical keycode.
  final int? keyCode;

  /// Mouse button index (e.g., 0 for left, 1 for right, 2 for middle).
  final int? button;

  /// Horizontal scroll wheel offset.
  final double scrollDeltaX;

  /// Vertical scroll wheel offset.
  final double scrollDeltaY;

  /// Text payload for direct international/Unicode text injection.
  final String? text;

  /// Duration in milliseconds for swipe actions.
  final int? durationMs;

  /// Navigation shortcut type if applicable.
  final NavigationAction? navigationAction;

  @override
  List<Object?> get props => [
    type,
    normalizedX,
    normalizedY,
    normalizedEndX,
    normalizedEndY,
    keyCode,
    button,
    scrollDeltaX,
    scrollDeltaY,
    text,
    durationMs,
    navigationAction,
  ];
}
