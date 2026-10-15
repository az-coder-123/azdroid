import 'package:desk_droid/features/productivity/domain/entities/remote_file_entity.dart';

/// Abstract contract governing bidirectional file transfer, remote file browsing, and APK sideloading.
abstract class FileTransferRepository {
  /// Pushes a local file from macOS host to the target Android device.
  Future<bool> pushFile(
    String deviceSerial,
    String localPath, {
    String? remoteDestination,
  });

  /// Pulls a remote file from Android to local destination on macOS.
  Future<bool> pullFile(
    String deviceSerial,
    String remotePath,
    String localDestination,
  );

  /// Lists files and directories in [remoteDirectory] on Android.
  Future<List<RemoteFileEntity>> listRemoteFiles(
    String deviceSerial,
    String remoteDirectory,
  );

  /// Installs an Android APK package onto the target device (`adb install -r`).
  Future<bool> installApk(String deviceSerial, String apkPath);

  /// Detects external physical SD card directory on the device if mounted.
  Future<String?> getExternalStorageDirectory(String deviceSerial);
}
