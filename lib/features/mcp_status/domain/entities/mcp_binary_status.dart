import 'package:equatable/equatable.dart';

/// Whether the precompiled MCP server bundled with this app can run.
enum McpBinaryAvailability {
  /// Present, and it answered the `tools/list` handshake.
  ready,

  /// Present, built for Intel only, on an Apple Silicon Mac where it did not
  /// start: Rosetta 2 is missing.
  needsRosetta,

  /// Present, but it did not answer the handshake.
  notResponding,

  /// Not in the app folder (debug builds do not embed it).
  missing,
}

/// The bundled `deskdroid-mcp` executable, as checked on this computer.
class McpBinaryStatus extends Equatable {
  const McpBinaryStatus({
    required this.availability,
    required this.executablePath,
    this.architectures = const [],
    this.runsTranslated = false,
  });

  final McpBinaryAvailability availability;

  /// Absolute path an AI client must launch.
  final String executablePath;

  /// CPU architectures in the executable (`x86_64`, `arm64`); empty when
  /// unknown or not applicable.
  final List<String> architectures;

  /// The executable is Intel-only on an Apple Silicon Mac, so it runs
  /// through Rosetta 2 (slower start).
  final bool runsTranslated;

  bool get isReady => availability == McpBinaryAvailability.ready;

  @override
  List<Object?> get props => [
    availability,
    executablePath,
    architectures,
    runsTranslated,
  ];
}
