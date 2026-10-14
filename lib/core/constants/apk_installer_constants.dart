/// Constants governing Android APK package inspection, sideloading, and installation.
class ApkInstallerConstants {
  const ApkInstallerConstants._();

  /// Standard file extension for Android application packages.
  static const String apkExtension = '.apk';

  /// Standard file extension for Android split package archives.
  static const String xapkExtension = '.xapk';

  /// Timeout in seconds when installing APK packages via ADB.
  static const int installTimeoutSeconds = 180;

  /// Timeout in seconds when querying APK metadata via local tools.
  static const int metadataTimeoutSeconds = 15;

  /// Default command-line flags passed to `adb install`.
  static const List<String> defaultInstallFlags = ['-r', '-g', '-t'];

  /// Android Asset Packaging Tool binary candidates.
  static const List<String> aaptBinaryNames = ['aapt2', 'aapt'];

  /// Standard known Android SDK build-tools directory path template.
  static const String androidSdkBuildToolsSubpath =
      'Library/Android/sdk/build-tools';
}
