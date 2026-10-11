/// Constants governing clipboard synchronization and drag-and-drop file transfers.
class ProductivityConstants {
  const ProductivityConstants._();

  /// Default remote target directory on Android for file transfers.
  static const String defaultRemoteDownloadDir = '/sdcard/Download/';

  /// Standard file extension for Android package archives.
  static const String apkExtension = '.apk';

  /// Interval in seconds for background periodic clipboard sync polling.
  static const int clipboardSyncIntervalSeconds = 4;

  /// Timeout in seconds when pushing standard files via ADB.
  static const int filePushTimeoutSeconds = 60;

  /// Timeout in seconds when installing APK packages via ADB.
  static const int apkInstallTimeoutSeconds = 120;

  /// Duration in seconds to display completed transfer toast banners.
  static const int transferBannerDisplaySeconds = 5;
}
