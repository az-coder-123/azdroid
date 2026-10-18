import 'package:desk_droid/core/platform/mcp_client_locations.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_counter.dart';
import 'package:desk_droid/features/mcp_status/data/services/mcp_config_snippet.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';

/// [McpStatusRepository] built from the executable check, the client
/// configuration reader, and the process counter.
class McpStatusRepositoryImpl implements McpStatusRepository {
  McpStatusRepositoryImpl({
    required McpBinaryInspector binaryInspector,
    required McpClientConfigReader configReader,
    required McpProcessCounter processCounter,
    required List<McpClientLocation> clients,
  }) : _binary = binaryInspector,
       _configs = configReader,
       _processes = processCounter,
       _locations = clients;

  final McpBinaryInspector _binary;
  final McpClientConfigReader _configs;
  final McpProcessCounter _processes;
  final List<McpClientLocation> _locations;

  @override
  Future<McpServerStatus> load() async {
    // Count first: the handshake below starts a server process of its own.
    final running = await countRunningSessions();
    final clients = await Future.wait(_locations.map(_configs.read));
    final binary = await _binary.inspect();
    return McpServerStatus(
      binary: binary,
      clients: clients,
      runningSessions: running,
    );
  }

  @override
  Future<int?> countRunningSessions() => _processes.count();

  @override
  String configurationSnippet() =>
      buildMcpConfigSnippet(_binary.executablePath);
}
