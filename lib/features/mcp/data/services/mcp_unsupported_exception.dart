/// Thrown when a tool cannot work on the connected device (a missing shell
/// command, an Android version limit, emulator-only support).
///
/// `McpToolExecutor` returns [message] to the agent as the tool error, so it
/// must say what is unsupported and what to do instead.
class McpUnsupportedOnDeviceException implements Exception {
  const McpUnsupportedOnDeviceException(this.message);

  final String message;

  @override
  String toString() => message;
}
