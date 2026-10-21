import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Lists running Azdroid MCP server processes: one per AI client session.
class McpProcessLister {
  McpProcessLister({
    required ProcessExecutor processExecutor,
    required HostProcessTools tools,
    required this.executableName,
  }) : _executor = processExecutor,
       _hostTools = tools;

  final ProcessExecutor _executor;
  final HostProcessTools _hostTools;

  /// File name of the server (`azdroid-mcp`, `azdroid-mcp.exe`).
  final String executableName;

  /// `pgrep` exit code when no process matches.
  static const int _noMatchExitCode = 1;

  /// Ids of running server processes, or `null` when the list cannot be
  /// read.
  Future<Set<int>?> listPids() async {
    final command = _hostTools.processList(
      executableName: executableName,
      scriptName: McpStatusConstants.sourceEntryPoint,
    );
    final result = await _executor.run(
      command.executable,
      command.arguments,
      timeout: McpStatusConstants.queryTimeout,
    );
    final noMatch =
        !_hostTools.os.isWindows && result.exitCode == _noMatchExitCode;
    if (noMatch) return const {};
    if (result.exitCode != 0) {
      AppLogger.debug(
        'Could not list MCP server processes: exit ${result.exitCode} '
        '${result.stderr}',
      );
      return null;
    }
    return _hostTools.parsePids(
      '${result.stdout}',
      executableName: executableName,
    );
  }
}
