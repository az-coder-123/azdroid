import 'package:wifi_desk/core/constants/apk_installer_constants.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_options.dart';
import 'package:wifi_desk/features/apk_installer/domain/entities/apk_install_result.dart';

/// Contract for ADB package operations (install, launch, uninstall).
abstract class ApkInstallerDatasource {
  Future<ApkInstallResult> installApk(
    String deviceSerial,
    String apkPath,
    ApkInstallOptions options, {
    String? packageName,
  });

  Future<bool> launchApp(String deviceSerial, String packageName);

  Future<bool> uninstallApp(String deviceSerial, String packageName);
}

/// Concrete implementation utilizing [AdbService] and [ProcessExecutor].
class ApkInstallerDatasourceImpl implements ApkInstallerDatasource {
  ApkInstallerDatasourceImpl({
    required this.adbService,
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  final AdbService adbService;
  final ProcessExecutor _executor;

  @override
  Future<ApkInstallResult> installApk(
    String deviceSerial,
    String apkPath,
    ApkInstallOptions options, {
    String? packageName,
  }) async {
    final adb = await adbService.resolveAdbPath();
    if (adb == null) {
      return ApkInstallResult(
        success: false,
        rawOutput: 'ADB executable not found on host system.',
        packageName: packageName,
        errorCode: 'ADB_NOT_FOUND',
        errorTitle: 'ADB Unavailable',
        errorDescription:
            'Could not resolve the path to Android Debug Bridge (adb).',
        suggestedAction:
            'Ensure Android platform-tools or Homebrew adb is installed.',
      );
    }

    final args = [
      '-s',
      deviceSerial,
      'install',
      ...options.toCliArgs(),
      apkPath,
    ];

    try {
      AppLogger.info('Starting ADB install: $adb ${args.join(' ')}');
      final result = await _executor.run(
        adb,
        args,
        timeout: const Duration(
          seconds: ApkInstallerConstants.installTimeoutSeconds,
        ),
      );

      final combined = '${result.stdout}\n${result.stderr}'.trim();
      return ApkInstallResult.fromAdbOutput(
        combined,
        packageName: packageName,
        exitCode: result.exitCode,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to execute adb install: $e',
        error: e,
        stackTrace: stack,
      );
      return ApkInstallResult(
        success: false,
        rawOutput: e.toString(),
        packageName: packageName,
        errorCode: 'PROCESS_EXCEPTION',
        errorTitle: 'Installation Process Interrupted',
        errorDescription:
            'An unexpected exception occurred during the ADB install process: $e',
        suggestedAction: 'Check Wi-Fi/USB device connectivity and try again.',
      );
    }
  }

  @override
  Future<bool> launchApp(String deviceSerial, String packageName) async {
    final adb = await adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      // Use monkey tool to trigger launcher intent cleanly without needing main activity class name
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'monkey',
        '-p',
        packageName,
        '-c',
        'android.intent.category.LAUNCHER',
        '1',
      ], timeout: const Duration(seconds: 10));
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.warning('Failed to launch package $packageName: $e');
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(String deviceSerial, String packageName) async {
    final adb = await adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'uninstall',
        packageName,
      ], timeout: const Duration(seconds: 15));
      final combined = '${result.stdout} ${result.stderr}'.toLowerCase();
      return result.exitCode == 0 && combined.contains('success');
    } catch (e) {
      AppLogger.warning('Failed to uninstall package $packageName: $e');
      return false;
    }
  }
}
