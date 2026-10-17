/// Animation duration tokens shared across the UI.
class AppMotion {
  const AppMotion._();

  /// Hover and selection highlight changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// Small state transitions such as chips, rows, and toggles.
  static const Duration medium = Duration(milliseconds: 200);

  /// Emphasized transitions such as countdown digits.
  static const Duration emphasized = Duration(milliseconds: 300);

  /// One full cycle of the discovery radar pulse.
  static const Duration radarPulse = Duration(milliseconds: 1800);
}
