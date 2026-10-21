import 'dart:io';

/// Desktop operating systems Azdroid can run on.
///
/// Pure Dart (no Flutter) so both the app and the MCP server can use it.
enum HostOs {
  macos,
  windows,
  linux;

  /// The operating system of the running process.
  static HostOs get current {
    if (Platform.isWindows) return HostOs.windows;
    if (Platform.isLinux) return HostOs.linux;
    return HostOs.macos;
  }

  bool get isWindows => this == HostOs.windows;

  /// File name of an executable, adding `.exe` on Windows.
  String executableName(String baseName) =>
      isWindows ? '$baseName.exe' : baseName;
}
