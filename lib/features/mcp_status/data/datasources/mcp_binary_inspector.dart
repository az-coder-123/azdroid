import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_file_probe.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';

/// Checks the `azdroid-mcp` executable bundled next to the app: whether
/// it exists, which CPUs it targets, and whether it answers a handshake.
class McpBinaryInspector {
  McpBinaryInspector({
    required this.executablePath,
    required ProcessExecutor processExecutor,
    required HostProcessTools tools,
    McpFileProbe files = const IoMcpFileProbe(),
  }) : _executor = processExecutor,
       _hostTools = tools,
       _fileProbe = files;

  final String executablePath;
  final ProcessExecutor _executor;
  final HostProcessTools _hostTools;
  final McpFileProbe _fileProbe;

  Future<McpBinaryStatus> inspect() async {
    if (!_fileProbe.fileExists(executablePath)) {
      return McpBinaryStatus(
        availability: McpBinaryAvailability.missing,
        executablePath: executablePath,
      );
    }
    final architectures = await _architectures();
    final translated =
        architectures.isNotEmpty &&
        !architectures.contains(McpStatusConstants.appleSiliconArchitecture) &&
        await _isAppleSilicon();
    final answers = await _answersHandshake();
    return McpBinaryStatus(
      availability: answers
          ? McpBinaryAvailability.ready
          : translated
          ? McpBinaryAvailability.needsRosetta
          : McpBinaryAvailability.notResponding,
      executablePath: executablePath,
      architectures: architectures,
      runsTranslated: translated,
    );
  }

  Future<List<String>> _architectures() async {
    final command = _hostTools.binaryArchitectures;
    if (command == null) return const [];
    final output = await _query(command, extra: [executablePath]);
    return output?.split(RegExp(r'\s+')).where((a) => a.isNotEmpty).toList() ??
        const [];
  }

  Future<bool> _isAppleSilicon() async {
    final command = _hostTools.appleSiliconCheck;
    if (command == null) return false;
    return (await _query(command)) == '1';
  }

  /// Output of a short query, or `null` when it fails (an Intel Mac has no
  /// `hw.optional.arm64`, for example).
  Future<String?> _query(
    HostCommand command, {
    List<String> extra = const [],
  }) async {
    final result = await _executor.run(command.executable, [
      ...command.arguments,
      ...extra,
    ], timeout: McpStatusConstants.queryTimeout);
    if (result.exitCode != 0) return null;
    return '${result.stdout}'.trim();
  }

  /// Starts the server, sends `tools/list`, and closes stdin so it exits.
  Future<bool> _answersHandshake() async {
    final Process process;
    try {
      process = await _executor.start(executablePath, const []);
    } on ProcessException catch (error) {
      // An Intel-only binary without Rosetta fails here ("Bad CPU type").
      AppLogger.warning('MCP server did not start', error: error);
      return false;
    }
    unawaited(process.stderr.drain<void>());
    try {
      process.stdin.writeln(McpStatusConstants.handshakeRequest);
      await process.stdin.close();
      final reply = await process.stdout
          .transform(utf8.decoder)
          .join()
          .timeout(McpStatusConstants.handshakeTimeout);
      return reply.contains(McpStatusConstants.handshakeReplyMarker);
    } on TimeoutException {
      AppLogger.warning('MCP server did not answer the handshake in time');
      return false;
    } on IOException catch (error) {
      AppLogger.warning('MCP server handshake failed', error: error);
      return false;
    } finally {
      process.kill();
    }
  }
}
