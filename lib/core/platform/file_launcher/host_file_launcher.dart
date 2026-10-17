/// Contract for opening or revealing local files with the host OS shell.
///
/// Implementations: `MacHostFileLauncher`, `WindowsHostFileLauncher`.
/// Selected once in `platform_di.dart`.
abstract class HostFileLauncher {
  /// Opens [path] (file or folder) with its default application.
  Future<bool> open(String path);

  /// Shows [path] selected in the OS file manager (Finder / Explorer).
  Future<bool> reveal(String path);
}
