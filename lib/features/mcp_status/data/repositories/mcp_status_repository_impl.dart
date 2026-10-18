import 'package:desk_droid/core/platform/mcp_client_locations.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_activity_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_lister.dart';
import 'package:desk_droid/features/mcp_status/data/services/mcp_config_snippet.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/domain/services/mcp_activity_snapshot_builder.dart';

/// [McpStatusRepository] built from the executable check, the client
/// configuration reader, the process lister, and the activity reader.
class McpStatusRepositoryImpl implements McpStatusRepository {
  McpStatusRepositoryImpl({
    required McpBinaryInspector binaryInspector,
    required McpClientConfigReader configReader,
    required McpProcessLister processLister,
    required McpActivityReader activityReader,
    required List<McpClientLocation> clients,
    DateTime Function()? clock,
  }) : _binary = binaryInspector,
       _configs = configReader,
       _processes = processLister,
       _activityFiles = activityReader,
       _locations = clients,
       _now = clock ?? DateTime.now;

  final McpBinaryInspector _binary;
  final McpClientConfigReader _configs;
  final McpProcessLister _processes;
  final McpActivityReader _activityFiles;
  final List<McpClientLocation> _locations;
  final DateTime Function() _now;

  @override
  Future<McpServerStatus> load() async {
    // List first: the handshake below starts a server process of its own.
    final pids = await listServerPids();
    final clients = await Future.wait(_locations.map(_configs.read));
    final binary = await _binary.inspect();
    return McpServerStatus(
      binary: binary,
      clients: clients,
      livePids: pids,
      activity: await readActivity(livePids: pids),
    );
  }

  @override
  Future<Set<int>?> listServerPids() async {
    final pids = await _processes.listPids();
    if (pids != null) {
      await _activityFiles.pruneStale(livePids: pids, now: _now());
    }
    return pids;
  }

  @override
  Future<McpActivitySnapshot> readActivity({
    required Set<int>? livePids,
  }) async => buildMcpActivitySnapshot(
    eventsByPid: await _activityFiles.readAll(),
    livePids: livePids,
    now: _now(),
  );

  @override
  String configurationSnippet() =>
      buildMcpConfigSnippet(_binary.executablePath);
}
