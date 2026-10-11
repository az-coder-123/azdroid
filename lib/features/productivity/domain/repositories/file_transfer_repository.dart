/// Abstract contract governing file transfer and APK sideloading to Android devices.
abstract class FileTransferRepository {
  /// Pushes a local file from macOS host to the target Android device.
  Future<bool> pushFile(
    String deviceSerial,
    String localPath, {
    String? remoteDestination,
  });

  /// Installs an Android APK package onto the target device (`adb install -r`).
  Future<bool> installApk(String deviceSerial, String apkPath);
}
