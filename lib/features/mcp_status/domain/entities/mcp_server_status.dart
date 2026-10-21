import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:equatable/equatable.dart';

/// Everything the app can observe about the Azdroid MCP server.
///
/// The app does not run the server: AI clients start it over stdio, so the
/// app checks the executable, reads client configurations, lists running
/// server processes, and reads the activity files the servers write.
class McpServerStatus extends Equatable {
  const McpServerStatus({
    required this.binary,
    required this.clients,
    required this.livePids,
    this.activity = const McpActivitySnapshot(),
  });

  final McpBinaryStatus binary;
  final List<McpClientStatus> clients;

  /// Running server processes, one per AI client session; `null` when the
  /// process list could not be read.
  final Set<int>? livePids;

  final McpActivitySnapshot activity;

  int? get runningSessions => livePids?.length;

  bool get anyClientConfigured =>
      clients.any((c) => c.setup == McpClientSetup.configured);

  McpServerStatus copyWith({
    Set<int>? livePids,
    McpActivitySnapshot? activity,
  }) => McpServerStatus(
    binary: binary,
    clients: clients,
    livePids: livePids ?? this.livePids,
    activity: activity ?? this.activity,
  );

  @override
  List<Object?> get props => [binary, clients, livePids, activity];
}
