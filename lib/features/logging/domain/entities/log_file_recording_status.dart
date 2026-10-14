import 'package:equatable/equatable.dart';

/// Real-time disk recording status for active logcat streaming sessions.
class LogFileRecordingStatus extends Equatable {
  const LogFileRecordingStatus({
    this.isRecording = false,
    this.targetFilePath,
    this.bytesWritten = 0,
    this.linesWritten = 0,
  });

  /// Factory representing idle / stopped recording state.
  factory LogFileRecordingStatus.idle() => const LogFileRecordingStatus();

  /// Whether logs are actively streaming to local disk.
  final bool isRecording;

  /// Full destination file path on the host macOS system.
  final String? targetFilePath;

  /// Approximate total bytes written to the file so far.
  final int bytesWritten;

  /// Total number of raw lines appended to the file.
  final int linesWritten;

  /// Human-readable formatted file size (e.g. '42 KB', '1.8 MB').
  String get formattedSize {
    if (bytesWritten < 1024) return '$bytesWritten B';
    if (bytesWritten < 1024 * 1024) {
      return '${(bytesWritten / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytesWritten / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  LogFileRecordingStatus copyWith({
    bool? isRecording,
    String? targetFilePath,
    int? bytesWritten,
    int? linesWritten,
  }) {
    return LogFileRecordingStatus(
      isRecording: isRecording ?? this.isRecording,
      targetFilePath: targetFilePath ?? this.targetFilePath,
      bytesWritten: bytesWritten ?? this.bytesWritten,
      linesWritten: linesWritten ?? this.linesWritten,
    );
  }

  @override
  List<Object?> get props => [
    isRecording,
    targetFilePath,
    bytesWritten,
    linesWritten,
  ];
}
