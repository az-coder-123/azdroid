import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// macOS [ImageClipboard] using AppleScript's `«class PNGf»` pasteboard type.
class MacImageClipboard implements ImageClipboard {
  const MacImageClipboard({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  /// Absolute path of the AppleScript runner.
  static const String osascriptExecutable = '/usr/bin/osascript';

  /// Upper bound for the AppleScript that copies the image.
  static const Duration timeout = Duration(seconds: 3);

  final ProcessExecutor _executor;

  /// AppleScript that reads [pngPath] into the pasteboard as PNG data.
  static String scriptFor(String pngPath) {
    final escaped = pngPath.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return 'set the clipboard to (read (POSIX file "$escaped") as «class PNGf»)';
  }

  @override
  Future<bool> copyPng(String pngPath) async {
    try {
      final result = await _executor.run(osascriptExecutable, [
        '-e',
        scriptFor(pngPath),
      ], timeout: timeout);
      return result.exitCode == 0;
    } on Exception catch (error) {
      AppLogger.debug('macOS image clipboard copy failed: $error');
      return false;
    }
  }
}
