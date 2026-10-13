import 'package:equatable/equatable.dart';

/// Represents a captured display video recording artifact.
class ScreenRecordingEntity extends Equatable {
  const ScreenRecordingEntity({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.duration,
    required this.recordedAt,
  });

  /// Absolute file system path where the MP4 video is saved on macOS host.
  final String filePath;

  /// Base file name (e.g. WifiDesk_Recording_20261013_192000.mp4).
  final String fileName;

  /// Size of the saved MP4 file in bytes.
  final int fileSizeBytes;

  /// Duration of the recorded video stream.
  final Duration duration;

  /// Timestamp when the recording was started.
  final DateTime recordedAt;

  @override
  List<Object?> get props => [
    filePath,
    fileName,
    fileSizeBytes,
    duration,
    recordedAt,
  ];
}
