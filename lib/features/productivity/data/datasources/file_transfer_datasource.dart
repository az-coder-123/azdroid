import 'dart:async';

import 'package:desk_droid/core/constants/adb_timeouts.dart';
import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/models/remote_file_model.dart';
import 'package:desk_droid/features/productivity/data/services/remote_media_scanner.dart';

/// Abstract datasource contract for ADB file push, pull, remote listing, and APK installation.
abstract class FileTransferDatasource {
  /// Pushes a local file to the destination path on the Android device.
  Future<bool> pushFile(
    String deviceSerial,
    String localPath,
    String remoteDestination,
  );

  /// Pulls a remote file from Android to a local destination on the host.
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
    RemoteMediaScanner? mediaScanner,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor(),
       _mediaScanner =
           mediaScanner ??
           RemoteMediaScanner(
             processExecutor: processExecutor ?? const DefaultProcessExecutor(),
           );

  final AdbService _adbService;
  final ProcessExecutor _executor;
  final RemoteMediaScanner _mediaScanner;

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
        // Media indexing is best effort and must not delay the push result.
        unawaited(
          _mediaScanner.scanPushedFile(
            adb: adb,
            serial: deviceSerial,
            remoteDirectory: remoteDestination,
            localPath: localPath,
          ),
        );
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
      ], timeout: AdbTimeouts.slowCommand);

      final stdoutStr = result.stdout.toString();
      if (result.exitCode != 0 && stdoutStr.trim().isEmpty) {
        final err = result.stderr.toString().trim();
        throw Exception(
          err.isNotEmpty ? err : 'Error reading $remoteDirectory',
        );
      }

      final lines = stdoutStr.splitLines();
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
      ], timeout: AdbTimeouts.shellCommand);

      final lines = result.stdout.toString().splitLines();
      for (final line in lines) {
        final path = line.trim();
        final name = path.split('/').last;
        final isExt =
            name.isNotEmpty &&
            !name.startsWith('.') &&
            !const {'emulated', 'self', 'sdcard0'}.contains(name);
        if (isExt) return path.endsWith('/') ? path : '$path/';
      }
    } on Exception catch (error) {
      AppLogger.warning(
        'Failed to query external storage on $deviceSerial',
        error: error,
      );
    }
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
