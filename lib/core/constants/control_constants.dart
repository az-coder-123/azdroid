/// Configuration constants for mouse, touch, scroll, and keyboard input injection.
class ControlConstants {
  const ControlConstants._();

  /// Default virtual device screen resolution width used when not dynamically detected.
  static const int defaultDisplayWidth = 1080;

  /// Default virtual device screen resolution height used when not dynamically detected.
  static const int defaultDisplayHeight = 2400;

  /// Default duration in milliseconds for swipe gestures translated from mouse drag or scroll.
  static const int defaultSwipeDurationMs = 120;

  /// Minimum travel distance (in logical pixels) to distinguish between a click/tap and a swipe.
  static const double minSwipeDistance = 8.0;

  /// Multiplier to translate macOS trackpad/mouse scroll wheel delta into Android swipe distance.
  static const double scrollFactor = 3.5;

  /// Throttle interval in milliseconds for continuous pointer move events to prevent socket/process saturation.
  static const int pointerThrottleMs = 40;

  /// Radius in pixels for rendering touch indicator ripple feedback.
  static const double touchIndicatorRadius = 24.0;

  /// Duration in milliseconds for the touch indicator fade-out animation.
  static const int touchIndicatorFadeMs = 300;
}
