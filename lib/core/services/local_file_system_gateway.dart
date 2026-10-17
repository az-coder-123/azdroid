import 'dart:io';

import 'package:desk_droid/core/services/app_logger.dart';

/// Contract for read-only queries against the host (macOS) file system.
abstract class LocalFileSystemGateway {
  /// Expands [paths] into a flat list of regular files.
  ///
  /// Files are kept as-is, directories are walked recursively without
  /// following symlinks, and missing or empty paths are skipped.
  List<String> expandToFiles(List<String> paths);

  /// Returns the size of the file at [path] in bytes, or `0` if unreadable.
  int fileSizeOf(String path);

  /// Creates [path] and missing parents. Throws [FileSystemException] on
  /// failure so callers can report it to the user.
  Future<void> ensureDirectory(String path);
}

/// `dart:io` implementation of [LocalFileSystemGateway].
class IoLocalFileSystemGateway implements LocalFileSystemGateway {
  const IoLocalFileSystemGateway();

  @override
  List<String> expandToFiles(List<String> paths) {
    final results = <String>[];
    for (final path in paths) {
      if (path.isEmpty) continue;
      switch (FileSystemEntity.typeSync(path)) {
        case FileSystemEntityType.file:
          results.add(path);
        case FileSystemEntityType.directory:
          results.addAll(_listFilesRecursively(path));
        default:
          AppLogger.debug('Skipping unsupported local path: $path');
      }
    }
    return results;
  }

  @override
  int fileSizeOf(String path) {
    try {
      final file = File(path);
      return file.existsSync() ? file.lengthSync() : 0;
    } on FileSystemException catch (error) {
      AppLogger.warning('Failed to read size of $path', error: error);
      return 0;
    }
  }

  @override
  Future<void> ensureDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  List<String> _listFilesRecursively(String directory) {
    try {
      return Directory(directory)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } on FileSystemException catch (error) {
      AppLogger.warning('Failed to list directory $directory', error: error);
      return const [];
    }
  }
}
