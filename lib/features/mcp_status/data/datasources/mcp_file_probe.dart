import 'dart:io';

/// The file system queries the MCP status checks need, so tests can run
/// without touching real files.
abstract class McpFileProbe {
  bool fileExists(String path);

  bool directoryExists(String path);

  /// File contents; throws [FileSystemException] when unreadable.
  Future<String> readText(String path);

  /// Regular files directly inside [directory]; empty when it is missing.
  List<String> listFiles(String directory);

  /// Last modification time; throws [FileSystemException] when missing.
  DateTime modifiedAt(String path);

  /// Deletes a file; throws [FileSystemException] on failure.
  Future<void> delete(String path);
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

  @override
  List<String> listFiles(String directory) {
    final folder = Directory(directory);
    if (!folder.existsSync()) return const [];
    return folder.listSync().whereType<File>().map((f) => f.path).toList();
  }

  @override
  DateTime modifiedAt(String path) => File(path).lastModifiedSync();

  @override
  Future<void> delete(String path) => File(path).delete();
}
