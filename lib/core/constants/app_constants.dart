/// General application-wide constants for DeskDroid.
class AppConstants {
  const AppConstants._();

  /// The official application display name.
  static const String appName = 'DeskDroid';

  /// Short marketing tagline for desktop window headers and about dialogs.
  static const String appTagline =
      'High-Performance Android Screen Mirroring & Workstation for macOS';

  /// Standard application version string.
  static const String appVersion = '1.0.1';

  /// Minimum supported window dimensions for macOS desktop.
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  /// Default window dimensions.
  static const double defaultWindowWidth = 1100.0;
  static const double defaultWindowHeight = 750.0;
}
