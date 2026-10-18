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

  /// Fingers a live touch stream can carry (scrcpy: the mouse finger and
  /// one virtual finger).
  static const int maxTouchPointers = 2;

  /// Initial distance between the two pinch fingers, as a fraction of the
  /// viewport's shorter side. Trackpad scale multiplies it.
  static const double pinchInitialSpanFraction = 0.3;

  /// Trackpad scale change (|scale - 1|) that turns a gesture into a pinch.
  static const double pinchScaleThreshold = 0.02;

  /// Trackpad rotation (radians) that turns a gesture into a pinch.
  static const double pinchRotationThreshold = 0.03;

  /// Trackpad pan (logical pixels) that turns a gesture into a one-finger
  /// drag, so a resting hand does not touch the phone.
  static const double panStartDistance = 2.0;

  /// Radius in pixels for rendering touch indicator ripple feedback.
  static const double touchIndicatorRadius = 24.0;

  /// Duration in milliseconds for the touch indicator fade-out animation.
  static const int touchIndicatorFadeMs = 300;
}
