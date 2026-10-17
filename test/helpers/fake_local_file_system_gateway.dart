import 'package:desk_droid/core/services/local_file_system_gateway.dart';

/// In-memory [LocalFileSystemGateway] that treats every path as a file.
///
/// Optional [directories] map a directory path to the files it contains.
class FakeLocalFileSystemGateway implements LocalFileSystemGateway {
  const FakeLocalFileSystemGateway({
    this.directories = const {},
    this.fileSize = 0,
  });

  final Map<String, List<String>> directories;
  final int fileSize;

  @override
  List<String> expandToFiles(List<String> paths) => [
    for (final path in paths)
      if (path.isNotEmpty) ...directories[path] ?? [path],
  ];

  @override
  int fileSizeOf(String path) => fileSize;

  @override
  Future<void> ensureDirectory(String path) async {}
}
