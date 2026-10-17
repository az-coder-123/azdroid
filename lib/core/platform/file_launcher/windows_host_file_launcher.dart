import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Windows [HostFileLauncher] backed by `explorer.exe`.
///
/// `explorer.exe` returns exit code 1 even on success, so the exit code is
/// ignored; only a failure to start the process counts as an error.
class WindowsHostFileLauncher implements HostFileLauncher {
  const WindowsHostFileLauncher({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  /// Windows shell executable used for both actions.
  static const String explorerExecutable = 'explorer.exe';

  /// Explorer argument prefix that opens the parent folder with [path] selected.
  static const String selectPrefix = '/select,';

  final ProcessExecutor _executor;

  @override
  Future<bool> open(String path) => _run([path]);

  @override
  Future<bool> reveal(String path) => _run(['$selectPrefix$path']);

  Future<bool> _run(List<String> arguments) async {
    try {
      await _executor.run(explorerExecutable, arguments);
      return true;
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to launch explorer.exe ${arguments.join(' ')}',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
