import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/models/remote_file_model.dart';

/// Abstract datasource contract for ADB file push, pull, remote listing, and APK installation.
abstract class FileTransferDatasource {
  /// Pushes a local file to the destination path on the Android device.
  Future<bool> pushFile(
    String deviceSerial,
    String localPath,
    String remoteDestination,
  );

  /// Pulls a remote file from Android to local destination on macOS.
  Future<bool> pullFile(
    String deviceSerial,
    String remotePath,
    String localDestination,
  );

  /// Lists files and directories in [remoteDirectory] on Android.
  Future<List<RemoteFileModel>> listRemoteFiles(
    String deviceSerial,
    String remoteDirectory,
  );

  /// Sideloads an APK package on the target device via `adb install -r`.
  Future<bool> installApk(String deviceSerial, String apkPath);

  /// Detects external physical SD card directory on the device if mounted.
  Future<String?> getExternalStorageDirectory(String deviceSerial);
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

      if (result.exitCode == 0) {
        _scanRemoteMedia(adb, deviceSerial, remoteDestination, localPath);
        return true;
      }
      return false;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to push file $localPath to $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> _scanRemoteMedia(
    String adb,
    String serial,
    String destination,
    String localPath,
  ) async {
    final lower = localPath.toLowerCase();
    final isMedia = const {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.mp4',
      '.mkv',
      '.mp3',
      '.wav',
    }.any(lower.endsWith);

    if (!isMedia) return;

    final fileName = localPath.split('/').last;
    final dest = destination.endsWith('/') ? destination : '$destination/';
    final remoteFile = '$dest$fileName';

    try {
      await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        'am',
        'broadcast',
        '-a',
        'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        '-d',
        'file://$remoteFile',
      ], timeout: const Duration(seconds: 4));
    } catch (_) {
      // Best effort scan notification
    }
  }

  @override
  Future<bool> pullFile(
    String deviceSerial,
    String remotePath,
    String localDestination,
  ) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(
        adb,
        ['-s', deviceSerial, 'pull', remotePath, localDestination],
        timeout: const Duration(
          seconds: ProductivityConstants.filePullTimeoutSeconds,
        ),
      );

      return result.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to pull remote file $remotePath from $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<List<RemoteFileModel>> listRemoteFiles(
    String deviceSerial,
    String remoteDirectory,
  ) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return [];

    try {
      final normDir = remoteDirectory.endsWith('/')
          ? remoteDirectory
          : '$remoteDirectory/';
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'ls',
        '-lp',
        normDir,
      ], timeout: const Duration(seconds: 8));

      final stdoutStr = result.stdout.toString();
      if (result.exitCode != 0 && stdoutStr.trim().isEmpty) {
        final err = result.stderr.toString().trim();
        throw Exception(
          err.isNotEmpty ? err : 'Error reading $remoteDirectory',
        );
      }

      final lines = stdoutStr.split('\n');
      final files = <RemoteFileModel>[];
      for (final line in lines) {
        final model = RemoteFileModel.fromLsLine(line, normDir);
        if (model != null) files.add(model);
      }
      return files;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to list remote files in $remoteDirectory on $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<String?> getExternalStorageDirectory(String deviceSerial) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return null;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'ls',
        '-d',
        '/storage/*',
      ], timeout: const Duration(seconds: 4));

      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        final path = line.trim();
        final name = path.split('/').last;
        final isExt =
            name.isNotEmpty &&
            !name.startsWith('.') &&
            !const {'emulated', 'self', 'sdcard0'}.contains(name);
        if (isExt) return path.endsWith('/') ? path : '$path/';
      }
    } catch (_) {}
    return null;
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
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to install APK $apkPath on $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
