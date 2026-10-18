import 'dart:io';

import 'package:desk_droid/features/mcp_status/data/datasources/mcp_file_probe.dart';

/// In-memory [McpFileProbe]: [files] maps paths to contents (`null` makes a
/// read fail), [directories] lists folders that exist.
class FakeMcpFileProbe implements McpFileProbe {
  FakeMcpFileProbe({this.files = const {}, this.directories = const {}});

  final Map<String, String?> files;
  final Set<String> directories;

  @override
  bool fileExists(String path) => files.containsKey(path);

  @override
  bool directoryExists(String path) => directories.contains(path);

  @override
  Future<String> readText(String path) async =>
      files[path] ?? (throw FileSystemException('Permission denied', path));
}
