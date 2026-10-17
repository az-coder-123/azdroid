import 'package:desk_droid/core/constants/adb_timeouts.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:path/path.dart' as p;

/// Asks Android's media scanner to index a file that was just pushed, so it
/// appears in Gallery and music apps without a reboot.
class RemoteMediaScanner {
  const RemoteMediaScanner({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  /// Local file extensions that Android indexes as media.
  static const Set<String> mediaExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.mp4',
    '.mkv',
    '.mp3',
    '.wav',
  };

  static const String _scanAction =
      'android.intent.action.MEDIA_SCANNER_SCAN_FILE';

  final ProcessExecutor _executor;

  /// Whether [localPath] has a media extension.
  static bool isMedia(String localPath) =>
      mediaExtensions.contains(p.extension(localPath).toLowerCase());

  /// Broadcasts a scan for the pushed copy of [localPath] in
  /// [remoteDirectory]. Best effort: failures are logged, never thrown.
  Future<void> scanPushedFile({
    required String adb,
    required String serial,
    required String remoteDirectory,
    required String localPath,
  }) async {
    if (!isMedia(localPath)) return;

    // Remote paths are Android paths and always use '/'.
    final dir = remoteDirectory.endsWith('/')
        ? remoteDirectory
        : '$remoteDirectory/';
    final remoteFile = '$dir${p.basename(localPath)}';

    try {
      await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        'am',
        'broadcast',
        '-a',
        _scanAction,
        '-d',
        'file://$remoteFile',
      ], timeout: AdbTimeouts.shellCommand);
    } on Exception catch (error) {
      AppLogger.debug('Media scanner broadcast failed for $remoteFile: $error');
    }
  }
}
