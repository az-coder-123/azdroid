import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:equatable/equatable.dart';

/// Everything the app can observe about the DeskDroid MCP server.
///
/// The app does not run the server: AI clients start it over stdio, so the
/// app can only check the executable, read client configurations, and count
/// running server processes.
class McpServerStatus extends Equatable {
  const McpServerStatus({
    required this.binary,
    required this.clients,
    required this.runningSessions,
  });

  final McpBinaryStatus binary;
  final List<McpClientStatus> clients;

  /// Server processes running now, one per connected AI client session.
  /// `null` when the process list could not be read.
  final int? runningSessions;

  bool get anyClientConfigured =>
      clients.any((c) => c.setup == McpClientSetup.configured);

  McpServerStatus copyWith({int? runningSessions}) => McpServerStatus(
    binary: binary,
    clients: clients,
    runningSessions: runningSessions ?? this.runningSessions,
  );

  @override
  List<Object?> get props => [binary, clients, runningSessions];
}
