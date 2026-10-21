import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:path/path.dart' as p;

/// Well-known host directories, resolved per operating system.
///
/// Pure Dart (no Flutter) so the logger and MCP server can depend on it.
abstract class HostPaths {
  /// Path manipulation rules (separator, roots) of the host OS.
  p.Context get context;

  /// The current user's home directory.
  String get homeDirectory;

  /// The user's Downloads folder.
  String get downloadsDirectory;

  /// Per-user application data folder for Azdroid.
  String get appDataDirectory;

  /// Writable temporary directory.
  String get tempDirectory;

  /// Folder of the running executable. Release builds place bundled helper
  /// tools (adb) here: `Contents/MacOS` on macOS, the exe folder on Windows.
  String get executableDirectory;

  /// Location of a bundled Flutter asset (key like `assets/x.jar`) in a
  /// release build, resolved relative to the running executable.
  String flutterAssetPath(String assetKey);

  /// Append-only diagnostic log file.
  ///
  /// POSIX hosts keep the historic `/tmp` location, next to the native
  /// plugin log (`/tmp/scrcpy_stream.log`).
  String get diagnosticLogFile;
}

/// [HostPaths] backed by environment variables and `dart:io`.
class SystemHostPaths implements HostPaths {
  SystemHostPaths({
    HostOs? os,
    Map<String, String>? environment,
    String? systemTempPath,
    String? executablePath,
  }) : _os = os ?? HostOs.current,
       _env = environment ?? Platform.environment,
       _systemTemp = systemTempPath ?? Directory.systemTemp.path,
       _executable = executablePath ?? Platform.resolvedExecutable;

  /// Folder name used under the per-user application data directory.
  static const String appFolderName = 'Azdroid';

  /// Legacy folder name for backwards compatibility.
  static const String legacyAppFolderName = 'DeskDroid';

  /// File name of the diagnostic log inside [tempDirectory].
  static const String diagnosticLogFileName = 'azdroid_dart.log';

  static const String _downloadsFolderName = 'Downloads';
  static const String _posixLogDirectory = '/tmp';

  final HostOs _os;
  final Map<String, String> _env;
  final String _systemTemp;
  final String _executable;

  @override
  p.Context get context =>
      p.Context(style: _os.isWindows ? p.Style.windows : p.Style.posix);

  @override
  String get homeDirectory {
    if (_os.isWindows) {
      final profile = _env['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) return profile;
      return '${_env['HOMEDRIVE'] ?? ''}${_env['HOMEPATH'] ?? ''}';
    }
    return _env['HOME'] ?? '';
  }

  @override
  String get downloadsDirectory =>
      context.join(homeDirectory, _downloadsFolderName);

  @override
  String get appDataDirectory => switch (_os) {
    HostOs.macos => context.join(
      homeDirectory,
      'Library',
      'Application Support',
      appFolderName,
    ),
    HostOs.windows => context.join(
      _env['APPDATA'] ?? context.join(homeDirectory, 'AppData', 'Roaming'),
      appFolderName,
    ),
    HostOs.linux => context.join(
      _env['XDG_DATA_HOME'] ?? context.join(homeDirectory, '.local', 'share'),
      appFolderName,
    ),
  };

  @override
  String get tempDirectory => _systemTemp;

  @override
  String get executableDirectory => context.dirname(_executable);

  @override
  String flutterAssetPath(String assetKey) {
    final exeDir = executableDirectory;
    // macOS bundles assets inside App.framework; Windows/Linux use data/.
    final assetsRoot = _os == HostOs.macos
        ? context.join(
            exeDir,
            '..',
            'Frameworks',
            'App.framework',
            'Versions',
            'A',
            'Resources',
            'flutter_assets',
          )
        : context.join(exeDir, 'data', 'flutter_assets');
    return context.normalize(
      context.joinAll([assetsRoot, ...assetKey.split('/')]),
    );
  }

  @override
  String get diagnosticLogFile => context.join(
    _os.isWindows ? tempDirectory : _posixLogDirectory,
    diagnosticLogFileName,
  );
}
