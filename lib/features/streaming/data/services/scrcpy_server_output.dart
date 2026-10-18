import 'package:desk_droid/core/extensions/line_split_extension.dart';

/// Meaning of one line printed by scrcpy-server on stdout or stderr.
enum ScrcpyServerEvent {
  /// The server identified the device and is about to open its socket.
  ready,

  /// The jar on the device is a different version than the client expects.
  /// The server exits; mirroring cannot start.
  versionMismatch,

  /// The server reported an error (for example an Android API it cannot use).
  error,

  /// Any other diagnostic output.
  other,
}

/// Classifies scrcpy-server output, which the app uses to detect readiness
/// and fail fast with a clear reason. Log formats are stable from v2.0 to
/// v5.x (`[server] INFO: Device: [...]`, `[server] ERROR: ...`).
class ScrcpyServerOutput {
  const ScrcpyServerOutput._();

  static const String _readyMarker = 'INFO: Device: [';
  static const String _versionMismatchMarker = 'does not match the client';
  static const String _errorMarker = 'ERROR:';

  /// Classifies a single output line.
  static ScrcpyServerEvent classify(String line) {
    if (line.contains(_versionMismatchMarker)) {
      return ScrcpyServerEvent.versionMismatch;
    }
    if (line.contains(_readyMarker)) return ScrcpyServerEvent.ready;
    if (line.contains(_errorMarker)) return ScrcpyServerEvent.error;
    return ScrcpyServerEvent.other;
  }

  /// Splits a raw output chunk (which may hold several lines) and classifies
  /// each non-empty line.
  static List<(ScrcpyServerEvent, String)> parseChunk(String chunk) => [
    for (final line in chunk.splitLines())
      if (line.trim().isNotEmpty) (classify(line), line.trim()),
  ];
}
