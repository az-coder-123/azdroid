import 'package:desk_droid/features/productivity/domain/entities/remote_file_entity.dart';

/// Data transfer model for remote Android filesystem items.
class RemoteFileModel extends RemoteFileEntity {
  const RemoteFileModel({
    required super.name,
    required super.path,
    required super.sizeBytes,
    required super.isDirectory,
    super.modifiedDate,
  });

  /// Parses a single line from `adb shell ls -lp` into a [RemoteFileModel].
  ///
  /// Example lines:
  /// `-rw-rw---- 1 root sdcard_rw 38941140 2026-08-15 01:01 video_360p-1.mp4`
  /// `drwxrwx--x 2 root sdcard_rw     4096 2026-09-13 22:40 NearSend/`
  static RemoteFileModel? fromLsLine(String line, String parentDirectory) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('total ')) return null;

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 8) return null;

    final permissions = parts[0];
    var isDir =
        permissions.startsWith('d') ||
        permissions.startsWith('l') ||
        parts.last.endsWith('/');
    final size = int.tryParse(parts[4]) ?? 0;
    final date = '${parts[5]} ${parts[6]}';

    // The filename may contain spaces, so join all tokens from index 7 onwards.
    var fileName = parts.sublist(7).join(' ');
    if (fileName.contains(' -> ')) {
      fileName = fileName.split(' -> ').first.trim();
    }
    if (fileName.endsWith('/')) {
      fileName = fileName.substring(0, fileName.length - 1);
    }

    if (fileName == '.' || fileName == '..') return null;

    final normalizedParent = parentDirectory.endsWith('/')
        ? parentDirectory.substring(0, parentDirectory.length - 1)
        : parentDirectory;

    return RemoteFileModel(
      name: fileName,
      path: '$normalizedParent/$fileName',
      sizeBytes: isDir ? 0 : size,
      isDirectory: isDir,
      modifiedDate: date,
    );
  }
}
