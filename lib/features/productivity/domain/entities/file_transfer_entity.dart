import 'package:equatable/equatable.dart';

/// Current lifecycle status of an active file transfer or APK installation.
enum FileTransferStatus { queued, inProgress, completed, failed }

/// Domain entity representing a local file being transferred or sideloaded.
class FileTransferEntity extends Equatable {
  const FileTransferEntity({
    required this.id,
    required this.fileName,
    required this.localPath,
    this.fileSizeBytes = 0,
    this.isApk = false,
    this.status = FileTransferStatus.queued,
    this.progress = 0.0,
    this.errorMessage,
  });

  /// Unique transfer identifier.
  final String id;

  /// File name with extension.
  final String fileName;

  /// Absolute file path on the macOS filesystem.
  final String localPath;

  /// Total file size in bytes.
  final int fileSizeBytes;

  /// Whether the file is an Android `.apk` package targeted for installation.
  final bool isApk;

  /// Current transfer progression status.
  final FileTransferStatus status;

  /// Progress fraction from 0.0 to 1.0.
  final double progress;

  /// Human-readable error description if transfer fails.
  final String? errorMessage;

  FileTransferEntity copyWith({
    String? id,
    String? fileName,
    String? localPath,
    int? fileSizeBytes,
    bool? isApk,
    FileTransferStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return FileTransferEntity(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isApk: isApk ?? this.isApk,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fileName,
    localPath,
    fileSizeBytes,
    isApk,
    status,
    progress,
    errorMessage,
  ];
}
