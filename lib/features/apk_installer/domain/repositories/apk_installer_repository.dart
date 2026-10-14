import 'package:wifi_desk/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_result.dart';

/// Contract for APK package inspection, sideloading, and remote lifecycle control.
abstract class ApkInstallerRepository {
  /// Parses local APK archive to extract application package name, label, versions, and icon.
  Future<ApkInfoEntity> inspectApk(String apkPath);

  /// Sideloads and installs the specified APK onto the target Android device with given options.
  Future<ApkInstallResult> installApk(
    String deviceSerial,
    String apkPath,
    ApkInstallOptions options,
  );

  /// Launches the main launcher activity of the specified package on the Android device.
  Future<bool> launchApp(String deviceSerial, String packageName);

  /// Uninstalls the specified package from the Android device.
  Future<bool> uninstallApp(String deviceSerial, String packageName);
}
