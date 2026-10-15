import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_state.dart';

/// Cubit managing remote Android filesystem exploration and pulling files to macOS.
class DeviceFileManagerCubit extends Cubit<DeviceFileManagerState> {
  DeviceFileManagerCubit({
    required this.repository,
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor,
       super(const DeviceFileManagerInitial());

  final FileTransferRepository repository;
  final ProcessExecutor _executor;

  /// Default local storage folder for downloaded files on Mac host.
  static String get defaultDownloadDirectory {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Downloads/DeskDroid';
  }

  String? _cachedExternalStoragePath;

  /// Returns the cached external storage directory if known.
  String? get externalStoragePath => _cachedExternalStoragePath;

  /// Loads contents of the given [directory] on Android (defaults to `/sdcard/Download`).
  Future<void> loadDirectory(
    String deviceSerial, {
    String directory = ProductivityConstants.defaultRemoteDownloadDir,
  }) async {
    emit(DeviceFileManagerLoading(currentDirectory: directory));

    try {
      final items = await repository.listRemoteFiles(deviceSerial, directory);
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cachedExternalStoragePath ??= await repository
          .getExternalStorageDirectory(deviceSerial);

      emit(
        DeviceFileManagerLoaded(
          currentDirectory: directory,
          files: items,
          selectedFiles: const {},
          externalStoragePath: _cachedExternalStoragePath,
        ),
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to read remote folder $directory on $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      emit(
        DeviceFileManagerError(
          message: 'Failed to access remote directory: $e',
          currentDirectory: directory,
        ),
      );
    }
  }

  /// Navigates directly to the external storage (MicroSD card) root directory.
  Future<void> openExternalStorage(String deviceSerial) async {
    _cachedExternalStoragePath ??= await repository.getExternalStorageDirectory(
      deviceSerial,
    );
    final target = _cachedExternalStoragePath ?? '/storage/';
    await loadDirectory(deviceSerial, directory: target);
  }

  /// Reloads the active directory.
  Future<void> refresh(String deviceSerial) async {
    final current = state;
    final dir = current is DeviceFileManagerLoaded
        ? current.currentDirectory
        : ProductivityConstants.defaultRemoteDownloadDir;
    await loadDirectory(deviceSerial, directory: dir);
  }

  /// Navigates to the parent directory if possible.
  Future<void> navigateUp(String deviceSerial) async {
    final current = state;
    if (current is! DeviceFileManagerLoaded) return;
    final parent = current.parentDirectory;
    if (parent != null) {
      await loadDirectory(deviceSerial, directory: parent);
    }
  }

  /// Sets the active search filter query.
  void setSearchQuery(String query) {
    final current = state;
    if (current is! DeviceFileManagerLoaded) return;
    emit(current.copyWith(searchQuery: query, clearStatusMessage: true));
  }

  /// Updates the sorting criteria.
  void setSortOption(FileSortOption sort) {
    final current = state;
    if (current is! DeviceFileManagerLoaded) return;
    emit(current.copyWith(sortOption: sort, clearStatusMessage: true));
  }

  /// Toggles selection of a remote file path.
  void toggleFileSelection(String remotePath) {
    final current = state;
    if (current is! DeviceFileManagerLoaded) return;

    final updated = Set<String>.from(current.selectedFiles);
    if (updated.contains(remotePath)) {
      updated.remove(remotePath);
    } else {
      updated.add(remotePath);
    }

    emit(current.copyWith(selectedFiles: updated, clearStatusMessage: true));
  }

  /// Selects or deselects all regular files currently visible in the directory.
  void selectAll(bool select) {
    final current = state;
    if (current is! DeviceFileManagerLoaded) return;

    if (!select) {
      emit(current.copyWith(selectedFiles: const {}, clearStatusMessage: true));
      return;
    }

    final allFilePaths = current.visibleFiles
        .where((f) => !f.isDirectory)
        .map((f) => f.path)
        .toSet();
    emit(
      current.copyWith(selectedFiles: allFilePaths, clearStatusMessage: true),
    );
  }

  /// Downloads all currently selected remote files to [destinationDirectory] on macOS.
  Future<void> downloadSelected(
    String deviceSerial, {
    String? destinationDirectory,
  }) async {
    final current = state;
    if (current is! DeviceFileManagerLoaded || current.selectedFiles.isEmpty) {
      return;
    }

    final targetDir = destinationDirectory ?? defaultDownloadDirectory;

    try {
      final dir = Directory(targetDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (e) {
      emit(
        DeviceFileManagerError(
          message: 'Failed to create local destination folder: $e',
          currentDirectory: current.currentDirectory,
        ),
      );
      return;
    }

    emit(current.copyWith(isDownloading: true, clearStatusMessage: true));

    int successCount = 0;
    for (final remotePath in current.selectedFiles) {
      final success = await repository.pullFile(
        deviceSerial,
        remotePath,
        targetDir,
      );
      if (success) {
        successCount++;
      }
    }

    final count = current.selectedFiles.length;
    emit(
      current.copyWith(
        isDownloading: false,
        selectedFiles: const {},
        statusMessage: 'Downloaded $successCount/$count file(s) to $targetDir',
      ),
    );
  }

  /// Opens the downloaded folder in macOS Finder.
  Future<void> openInFinder([String? targetDir]) async {
    final path = targetDir ?? defaultDownloadDirectory;
    try {
      await _executor.run('open', [path]);
    } catch (e) {
      AppLogger.warning('Failed to open folder in Finder: $e');
    }
  }
}
