/// MCP protocol revisions this server speaks, newest first.
///
/// - `2024-11-05`: base protocol, `initialize` `instructions`.
/// - `2025-03-26`: adds tool `annotations` (readOnlyHint, destructiveHint,
///   idempotentHint). Clients only rely on them when the session uses this
///   revision or later, so the server must not pin itself to `2024-11-05`.
/// - `2025-06-18`: current revision; nothing this server uses changed.
///
/// The server does not support JSON-RPC batches (a single message per line),
/// which only `2025-03-26` allowed; clients do not send them in practice.
const List<String> mcpSupportedProtocolVersions = [
  '2025-06-18',
  '2025-03-26',
  '2024-11-05',
];

/// The revision to answer an `initialize` that asked for [requested]: the
/// same one when supported, otherwise the newest this server supports (the
/// client then decides whether it can continue), as the specification says.
String negotiateMcpProtocolVersion(Object? requested) =>
    requested is String && mcpSupportedProtocolVersions.contains(requested)
    ? requested
    : mcpSupportedProtocolVersions.first;
