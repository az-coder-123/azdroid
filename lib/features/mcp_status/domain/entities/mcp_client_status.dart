import 'package:equatable/equatable.dart';

/// How an AI client is set up to launch the DeskDroid MCP server.
enum McpClientSetup {
  /// Its configuration launches this app's `deskdroid-mcp`.
  configured,

  /// Its configuration launches another copy (an older install or a source
  /// checkout); see [McpClientStatus.configuredCommand].
  configuredElsewhere,

  /// The client is installed, but DeskDroid is not in its configuration.
  notConfigured,

  /// No configuration file and no folder for it: the client is probably not
  /// installed.
  clientNotFound,

  /// The configuration file exists but is not valid JSON.
  unreadable,
}

/// One AI client's DeskDroid MCP setup on this computer.
class McpClientStatus extends Equatable {
  const McpClientStatus({
    required this.name,
    required this.configPath,
    required this.setup,
    this.configuredCommand,
  });

  final String name;

  /// The client's MCP configuration file.
  final String configPath;

  final McpClientSetup setup;

  /// The command the client runs for DeskDroid, when it has an entry.
  final String? configuredCommand;

  @override
  List<Object?> get props => [name, configPath, setup, configuredCommand];
}
