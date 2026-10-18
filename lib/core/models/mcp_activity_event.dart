import 'dart:convert';

import 'package:equatable/equatable.dart';

/// What an MCP server process recorded.
enum McpActivityKind {
  /// The AI client connected (`initialize`); carries its name.
  sessionStart('start'),

  /// One `tools/call`; carries the tool, device, result, and duration.
  toolCall('tool');

  const McpActivityKind(this.wireName);

  final String wireName;
}

/// One line of an MCP activity file (`<pid>.jsonl`), shared by the MCP
/// server (writer) and the app (reader).
///
/// Tool arguments are never recorded: they may hold text the user types.
/// Pure Dart (no Flutter). Format: docs/features/mcp-activity-log.md.
class McpActivityEvent extends Equatable {
  const McpActivityEvent({
    required this.kind,
    required this.at,
    this.clientName,
    this.tool,
    this.deviceSerial,
    this.succeeded,
    this.durationMs,
  });

  const McpActivityEvent.sessionStart({
    required this.at,
    required this.clientName,
  }) : kind = McpActivityKind.sessionStart,
       tool = null,
       deviceSerial = null,
       succeeded = null,
       durationMs = null;

  const McpActivityEvent.toolCall({
    required this.at,
    required this.tool,
    required this.deviceSerial,
    required this.succeeded,
    required this.durationMs,
  }) : kind = McpActivityKind.toolCall,
       clientName = null;

  final McpActivityKind kind;

  /// When the event happened (a tool call: when it finished).
  final DateTime at;
  final String? clientName;
  final String? tool;

  /// The device the tool acted on; `null` for device-less tools.
  final String? deviceSerial;
  final bool? succeeded;
  final int? durationMs;

  static const String _kindKey = 'kind';
  static const String _atKey = 'at';
  static const String _clientKey = 'client';
  static const String _toolKey = 'tool';
  static const String _deviceKey = 'device';
  static const String _okKey = 'ok';
  static const String _msKey = 'ms';

  /// One JSON object, no newline.
  String toLine() => jsonEncode({
    _kindKey: kind.wireName,
    _atKey: at.toUtc().toIso8601String(),
    _clientKey: ?clientName,
    _toolKey: ?tool,
    _deviceKey: ?deviceSerial,
    _okKey: ?succeeded,
    _msKey: ?durationMs,
  });

  /// Parses one line; `null` for a blank, partial, or unknown line (a
  /// line may be half-written while it is read).
  static McpActivityEvent? tryParse(String line) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final json = decoded;
    final kind = McpActivityKind.values
        .where((k) => k.wireName == json[_kindKey])
        .firstOrNull;
    final at = DateTime.tryParse('${json[_atKey]}');
    if (kind == null || at == null) return null;
    String? text(String key) =>
        json[key] is String ? json[key]! as String : null;
    return McpActivityEvent(
      kind: kind,
      at: at,
      clientName: text(_clientKey),
      tool: text(_toolKey),
      deviceSerial: text(_deviceKey),
      succeeded: json[_okKey] is bool ? json[_okKey]! as bool : null,
      durationMs: json[_msKey] is int ? json[_msKey]! as int : null,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    at,
    clientName,
    tool,
    deviceSerial,
    succeeded,
    durationMs,
  ];
}
