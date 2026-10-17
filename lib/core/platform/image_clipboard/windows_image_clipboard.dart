import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Windows [ImageClipboard] using PowerShell and `System.Windows.Forms`.
///
/// `Clipboard.SetImage` needs a single-threaded apartment, hence `-STA`.
/// PowerShell start-up adds a few hundred milliseconds; a native plugin
/// method can replace this later without changing the contract.
class WindowsImageClipboard implements ImageClipboard {
  const WindowsImageClipboard({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  /// PowerShell executable shipped with every supported Windows version.
  static const String powershellExecutable = 'powershell.exe';

  /// Upper bound for PowerShell start-up plus the copy.
  static const Duration timeout = Duration(seconds: 8);

  final ProcessExecutor _executor;

  /// PowerShell script that loads [pngPath] and sets it as clipboard image.
  static String scriptFor(String pngPath) {
    // Single quotes are escaped by doubling in PowerShell literal strings.
    final escaped = pngPath.replaceAll("'", "''");
    return 'Add-Type -AssemblyName System.Windows.Forms, System.Drawing; '
        "\$img = [System.Drawing.Image]::FromFile('$escaped'); "
        r'[System.Windows.Forms.Clipboard]::SetImage($img); '
        r'$img.Dispose()';
  }

  @override
  Future<bool> copyPng(String pngPath) async {
    try {
      final result = await _executor.run(powershellExecutable, [
        '-NoProfile',
        '-NonInteractive',
        '-STA',
        '-Command',
        scriptFor(pngPath),
      ], timeout: timeout);
      return result.exitCode == 0;
    } on Exception catch (error) {
      AppLogger.debug('Windows image clipboard copy failed: $error');
      return false;
    }
  }
}
