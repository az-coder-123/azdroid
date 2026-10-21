import 'package:desk_droid/core/platform/host_paths.dart';

/// Builds file paths for logcat recordings and exported snapshots.
///
/// Single owner of the log file naming scheme, so recordings, custom-folder
/// recordings, and snapshots stay consistent on every OS.
class LogFilePathBuilder {
  LogFilePathBuilder({required HostPaths hostPaths, DateTime Function()? clock})
    : _paths = hostPaths,
      _clock = clock ?? DateTime.now;

  /// Folder created inside Downloads for Azdroid log files.
  static const String logFolderName = 'azdroid_logs';

  static const String _recordingPrefix = 'logcat';
  static const String _snapshotPrefix = 'logcat_snapshot';
  static const String _extension = '.log';
  static final RegExp _unsafeChars = RegExp(r'[^a-zA-Z0-9_-]');

  final HostPaths _paths;
  final DateTime Function() _clock;

  /// Default folder for log files: `<Downloads>/azdroid_logs`.
  String get defaultDirectory =>
      _paths.context.join(_paths.downloadsDirectory, logFolderName);

  /// Path for a live recording, in [directory] or the default folder.
  String recordingPath(String deviceSerial, {String? directory}) =>
      _build(_recordingPrefix, deviceSerial, directory);

  /// Path for a one-off snapshot export, in [directory] or the default folder.
  String snapshotPath(String deviceSerial, {String? directory}) =>
      _build(_snapshotPrefix, deviceSerial, directory);

  String _build(String prefix, String serial, String? directory) {
    final safeSerial = serial.replaceAll(_unsafeChars, '_');
    final fileName = '${prefix}_${safeSerial}_${_timestamp()}$_extension';
    return _paths.context.join(directory ?? defaultDirectory, fileName);
  }

  /// `yyyyMMdd_HHmmss` in local time.
  String _timestamp() {
    final now = _clock();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
