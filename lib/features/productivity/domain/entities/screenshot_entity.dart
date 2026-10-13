import 'package:equatable/equatable.dart';

/// Represents a captured display screenshot artifact.
class ScreenshotEntity extends Equatable {
  const ScreenshotEntity({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.capturedAt,
    this.copiedToClipboard = true,
  });

  /// Absolute file system path where the PNG screenshot is saved.
  final String filePath;

  /// Base file name (e.g. WifiDesk_Screenshot_20261013_183500.png).
  final String fileName;

  /// Size of the saved image file in bytes.
  final int fileSizeBytes;

  /// Exact timestamp when the screenshot was captured.
  final DateTime capturedAt;

  /// Whether the image was also successfully written to the macOS system clipboard.
  final bool copiedToClipboard;

  @override
  List<Object?> get props => [
    filePath,
    fileName,
    fileSizeBytes,
    capturedAt,
    copiedToClipboard,
  ];
}
