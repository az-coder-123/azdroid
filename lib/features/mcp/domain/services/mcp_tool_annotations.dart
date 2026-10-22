// Standard MCP tool annotation presets applied to every catalog entry.
//
// The MCP specification defaults unknown tools to `destructiveHint: true`
// and `readOnlyHint: false`, so every published tool must carry an explicit
// preset — otherwise clients wrongly flag safe input tools as destructive.
//
// Policy (enforced by `test/architecture/mcp_tool_catalog_guard_test.dart`):
// - readOnlyToolAnnotations: pure inspection, never mutates device state.
// - inputToolAnnotations: simulates user interaction (taps, gestures, text).
// - stateSetToolAnnotations: converges the device toward a target state,
//   safe to replay.
// - destructiveToolAnnotations: may destroy data or make hard-to-revert
//   state changes; clients should confirm with the user first.
// - destructiveStateSetToolAnnotations: the same risk, but replay-safe (it
//   sets a fixed state or overwrites the same file): radios, network modes,
//   permission revocation, file transfers that overwrite.

/// Pure inspection tools: read device state, never mutate it.
const Map<String, dynamic> readOnlyToolAnnotations = {
  'readOnlyHint': true,
  'destructiveHint': false,
  'idempotentHint': true,
};

/// Interaction tools: simulate user input events (tap, swipe, type, launch).
const Map<String, dynamic> inputToolAnnotations = {
  'readOnlyHint': false,
  'destructiveHint': false,
  'idempotentHint': false,
};

/// State-converging tools: set the device to a target state, replay-safe.
const Map<String, dynamic> stateSetToolAnnotations = {
  'readOnlyHint': false,
  'destructiveHint': false,
  'idempotentHint': true,
};

/// Replay-safe tools that can still destroy data or cut the agent off: turning
/// Wi-Fi off or Airplane mode on drops a Wi-Fi ADB connection (no remote way
/// back), revoking a permission kills the app process, file transfers
/// overwrite an existing file.
const Map<String, dynamic> destructiveStateSetToolAnnotations = {
  'readOnlyHint': false,
  'destructiveHint': true,
  'idempotentHint': true,
};

/// Destructive tools: may destroy data or cause hard-to-revert state changes.
const Map<String, dynamic> destructiveToolAnnotations = {
  'readOnlyHint': false,
  'destructiveHint': true,
  'idempotentHint': false,
};
