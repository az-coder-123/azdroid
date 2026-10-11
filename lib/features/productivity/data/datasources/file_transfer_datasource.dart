import 'package:wifi_desk/core/constants/productivity_constants.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Abstract datasource contract for ADB file push and APK installation.
abstract class FileTransferDatasource {
  /// Pushes a local file to the destination path on the Android device.
  Future<bool> pushFile(
    String deviceSerial,
    String localPath,
    String remoteDestination,
  );

  /// Sideloads an APK package on the target device via `adb install -r`.
  Future<bool> installApk(String deviceSerial, String apkPath);
}

/// Concrete implementation of [FileTransferDatasource] executing ADB commands.
class FileTransferDatasourceImpl implements FileTransferDatasource {
  FileTransferDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  @override
  Future<bool> pushFile(
    String deviceSerial,
    String localPath,
    String remoteDestination,
  ) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(
        adb,
        ['-s', deviceSerial, 'push', localPath, remoteDestination],
        timeout: const Duration(
          seconds: ProductivityConstants.filePushTimeoutSeconds,
        ),
      );

      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> installApk(String deviceSerial, String apkPath) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(
        adb,
        ['-s', deviceSerial, 'install', '-r', apkPath],
        timeout: const Duration(
          seconds: ProductivityConstants.apkInstallTimeoutSeconds,
        ),
      );

      final combined = '${result.stdout} ${result.stderr}'.toLowerCase();
      return result.exitCode == 0 || combined.contains('success');
    } catch (_) {
      return false;
    }
  }
}
