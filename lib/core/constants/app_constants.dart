/// General application-wide constants for DeskDroid.
class AppConstants {
  const AppConstants._();

  /// The official application display name.
  static const String appName = 'Azdroid';

  /// Short marketing tagline for desktop window headers and about dialogs.
  static const String appTagline =
      'High-Performance Android Screen Mirroring & Workstation for macOS & Windows';

  /// Application version; must equal the `version:` name in pubspec.yaml
  /// (checked by test/unit/app_version_test.dart). Release steps:
  /// docs/release-guide.md.
  static const String appVersion = '1.3.0';

  /// Minimum supported window dimensions for macOS desktop.
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  /// Default window dimensions.
  static const double defaultWindowWidth = 1100.0;
  static const double defaultWindowHeight = 750.0;
}
