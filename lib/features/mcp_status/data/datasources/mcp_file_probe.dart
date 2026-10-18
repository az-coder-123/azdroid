import 'dart:io';

/// The file system queries the MCP status checks need, so tests can run
/// without touching real files.
abstract class McpFileProbe {
  bool fileExists(String path);

  bool directoryExists(String path);

  /// File contents; throws [FileSystemException] when unreadable.
  Future<String> readText(String path);
}

/// `dart:io` implementation of [McpFileProbe].
class IoMcpFileProbe implements McpFileProbe {
  const IoMcpFileProbe();

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  Future<String> readText(String path) => File(path).readAsString();
}
