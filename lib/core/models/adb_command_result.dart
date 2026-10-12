/// Result of an ADB command execution containing status flag and output message.
class AdbCommandResult {
  const AdbCommandResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}
