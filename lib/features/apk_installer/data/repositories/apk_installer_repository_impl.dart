import 'package:desk_droid/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_metadata_datasource.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_info_entity.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:desk_droid/features/apk_installer/domain/entities/apk_install_result.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';

/// Concrete implementation coordinating APK metadata extraction and ADB installation.
class ApkInstallerRepositoryImpl implements ApkInstallerRepository {
  const ApkInstallerRepositoryImpl({
    required this.metadataDatasource,
    required this.installerDatasource,
  });

  final ApkMetadataDatasource metadataDatasource;
  final ApkInstallerDatasource installerDatasource;

  @override
  Future<ApkInfoEntity> inspectApk(String apkPath) {
    return metadataDatasource.inspectApk(apkPath);
  }

  @override
  Future<ApkInstallResult> installApk(
    String deviceSerial,
    String apkPath,
    ApkInstallOptions options,
  ) async {
    // Attempt to inspect first so we can tie package name to the result
    final info = await metadataDatasource.inspectApk(apkPath);
    return installerDatasource.installApk(
      deviceSerial,
      apkPath,
      options,
      packageName: info.packageName,
    );
  }

  @override
  Future<bool> launchApp(String deviceSerial, String packageName) {
    return installerDatasource.launchApp(deviceSerial, packageName);
  }

  @override
  Future<bool> uninstallApp(String deviceSerial, String packageName) {
    return installerDatasource.uninstallApp(deviceSerial, packageName);
  }
}
