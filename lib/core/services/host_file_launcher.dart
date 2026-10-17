import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Contract for opening or revealing local files with the host OS shell.
abstract class HostFileLauncher {
  /// Opens [path] with its default macOS application.
  Future<bool> open(String path);

  /// Reveals and selects [path] in a Finder window.
  Future<bool> revealInFinder(String path);
}

/// macOS implementation backed by the `/usr/bin/open` command.
class MacHostFileLauncher implements HostFileLauncher {
  const MacHostFileLauncher({
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  /// Absolute path of the macOS `open` utility.
  static const String openExecutable = '/usr/bin/open';

  /// Flag that tells `open` to reveal the file in Finder instead of opening it.
  static const String revealFlag = '-R';

  final ProcessExecutor _executor;

  @override
  Future<bool> open(String path) => _run([path]);

  @override
  Future<bool> revealInFinder(String path) => _run([revealFlag, path]);

  Future<bool> _run(List<String> arguments) async {
    try {
      final result = await _executor.run(openExecutable, arguments);
      if (result.exitCode == 0) return true;
      AppLogger.warning(
        'open ${arguments.join(' ')} exited with ${result.exitCode}: '
        '${result.stderr}',
      );
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to launch open ${arguments.join(' ')}',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }
}
