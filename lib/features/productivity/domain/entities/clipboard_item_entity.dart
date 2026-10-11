import 'package:equatable/equatable.dart';

/// Origin of a synchronized clipboard text snippet.
enum ClipboardSource {
  host, // macOS Pasteboard
  device, // Android System Clipboard
}

/// Domain entity representing a synchronized clipboard entry.
class ClipboardItemEntity extends Equatable {
  const ClipboardItemEntity({
    required this.text,
    required this.source,
    required this.timestamp,
  });

  /// The text content of the clipboard.
  final String text;

  /// Originating platform.
  final ClipboardSource source;

  /// Local time when the text was synchronized.
  final DateTime timestamp;

  @override
  List<Object?> get props => [text, source, timestamp];
}
