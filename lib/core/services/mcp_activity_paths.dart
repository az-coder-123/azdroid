import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/platform/host_paths.dart';

/// Where MCP servers record their activity and the app reads it, per user.
///
/// Pure Dart (no Flutter): the MCP server uses it too.
class McpActivityPaths {
  const McpActivityPaths(this._paths);

  final HostPaths _paths;

  String get directory => _paths.context.join(
    _paths.appDataDirectory,
    McpStatusConstants.activityFolderName,
  );

  /// The activity file of the server process [pid].
  String fileFor(int pid) => _paths.context.join(
    directory,
    '$pid${McpStatusConstants.activityFileExtension}',
  );

  /// The process id encoded in an activity file name, or `null` when the
  /// file is not an activity file.
  int? pidOf(String filePath) {
    final name = _paths.context.basename(filePath);
    if (!name.endsWith(McpStatusConstants.activityFileExtension)) return null;
    return int.tryParse(
      name.substring(
        0,
        name.length - McpStatusConstants.activityFileExtension.length,
      ),
    );
  }
}
