import 'dart:io';

import 'package:desk_droid/features/mcp_status/data/datasources/mcp_file_probe.dart';
import 'package:path/path.dart' as p;

/// In-memory [McpFileProbe]: [files] maps paths to contents (`null` makes a
/// read fail), [directories] lists folders that exist, [modified] gives
/// file times (default: the epoch).
class FakeMcpFileProbe implements McpFileProbe {
  FakeMcpFileProbe({
    Map<String, String?>? files,
    this.directories = const {},
    this.modified = const {},
  }) : files = files ?? {};

  final Map<String, String?> files;
  final Set<String> directories;
  final Map<String, DateTime> modified;
  final List<String> deleted = [];

  @override
  bool fileExists(String path) => files.containsKey(path);

  @override
  bool directoryExists(String path) => directories.contains(path);

  @override
  Future<String> readText(String path) async =>
      files[path] ?? (throw FileSystemException('Permission denied', path));

  @override
  List<String> listFiles(String directory) =>
      files.keys.where((f) => p.posix.dirname(f) == directory).toList();

  @override
  DateTime modifiedAt(String path) =>
      modified[path] ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<void> delete(String path) async {
    files.remove(path);
    deleted.add(path);
  }
}
