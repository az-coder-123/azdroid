import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/platform/mcp_client_locations.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_file_probe.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:path/path.dart' as p;

/// Reads an AI client's MCP configuration and finds the Azdroid entry.
///
/// Read-only: the app never edits client configuration files.
class McpClientConfigReader {
  McpClientConfigReader({
    required this.expectedExecutable,
    required p.Context pathContext,
    McpFileProbe files = const IoMcpFileProbe(),
  }) : _path = pathContext,
       _fileProbe = files;

  /// This app's `azdroid-mcp`; an entry launching it is [McpClientSetup.configured].
  final String expectedExecutable;
  final p.Context _path;
  final McpFileProbe _fileProbe;

  static const String _serversKey = 'mcpServers';
  static const String _commandKey = 'command';
  static const String _argsKey = 'args';

  Future<McpClientStatus> read(McpClientLocation client) async {
    McpClientStatus status(McpClientSetup setup, [String? command]) =>
        McpClientStatus(
          name: client.name,
          configPath: client.configPath,
          setup: setup,
          configuredCommand: command,
        );

    if (!_fileProbe.fileExists(client.configPath)) {
      final folder = _path.dirname(client.configPath);
      return status(
        _fileProbe.directoryExists(folder)
            ? McpClientSetup.notConfigured
            : McpClientSetup.clientNotFound,
      );
    }
    try {
      final json = jsonDecode(await _fileProbe.readText(client.configPath));
      final command = _azdroidCommand(json);
      if (command == null) return status(McpClientSetup.notConfigured);
      return status(
        _isThisApp(command)
            ? McpClientSetup.configured
            : McpClientSetup.configuredElsewhere,
        command,
      );
    } on FormatException catch (error) {
      AppLogger.warning('Invalid JSON in ${client.configPath}', error: error);
      return status(McpClientSetup.unreadable);
    } on FileSystemException catch (error) {
      AppLogger.warning('Cannot read ${client.configPath}', error: error);
      return status(McpClientSetup.unreadable);
    }
  }

  /// The command line of the first server entry that runs Azdroid's MCP
  /// server (precompiled, `dart run`, or the start script), whatever its key.
  String? _azdroidCommand(Object? json) {
    if (json is! Map) return null;
    final servers = json[_serversKey];
    if (servers is! Map) return null;
    for (final entry in servers.values) {
      if (entry is! Map) continue;
      final command = entry[_commandKey];
      if (command is! String) continue;
      final args = [
        for (final a in entry[_argsKey] is List ? entry[_argsKey] as List : [])
          '$a',
      ];
      if (_runsAzdroid(command, args)) {
        return [command, ...args].join(' ');
      }
    }
    return null;
  }

  bool _runsAzdroid(String command, List<String> args) {
    // Lowercase: Windows file names ignore case (AZDROID-MCP.EXE / DESKDROID-MCP.EXE).
    final name = _path.basenameWithoutExtension(command).toLowerCase();
    return name == McpStatusConstants.executableBaseName ||
        name == McpStatusConstants.legacyExecutableBaseName ||
        command.contains(McpStatusConstants.startScriptName) ||
        args.any(
          (a) =>
              a.contains(McpStatusConstants.sourceEntryPoint) ||
              a.contains(McpStatusConstants.legacySourceEntryPoint),
        );
  }

  bool _isThisApp(String command) => _path.equals(
    _path.normalize(command),
    _path.normalize(expectedExecutable),
  );
}
