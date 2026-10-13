import 'package:equatable/equatable.dart';

/// Represents a file or directory on the connected Android device filesystem.
class RemoteFileEntity extends Equatable {
  const RemoteFileEntity({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.isDirectory,
    this.modifiedDate,
  });

  /// Name of the remote file or directory.
  final String name;

  /// Full absolute path on Android (e.g. `/sdcard/Download/photo.jpg`).
  final String path;

  /// File size in bytes (0 for directories).
  final int sizeBytes;

  /// Whether this entry is a directory.
  final bool isDirectory;

  /// Raw or formatted modification timestamp string if available.
  final String? modifiedDate;

  /// Returns human-readable file size (e.g., '14.2 MB', '850 KB').
  String get formattedSize {
    if (isDirectory) return '--';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// File extension in lower case (e.g., 'mp4', 'jpg').
  String get extension {
    if (isDirectory || !name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  /// Whether the file is an image.
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(extension);

  /// Whether the file is a video.
  bool get isVideo =>
      ['mp4', 'mkv', 'mov', 'webm', 'avi', '3gp'].contains(extension);

  /// Whether the file is audio.
  bool get isAudio =>
      ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(extension);

  /// Whether the file is an APK installer.
  bool get isApk => extension == 'apk';

  @override
  List<Object?> get props => [name, path, sizeBytes, isDirectory, modifiedDate];
}
