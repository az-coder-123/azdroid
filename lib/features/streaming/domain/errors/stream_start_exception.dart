/// Reasons a mirroring session cannot start.
enum StreamStartFailure {
  /// The phone has not accepted this computer's USB debugging key.
  deviceUnauthorized,

  /// ADB lists the device, but it is not ready (for example `offline`).
  deviceOffline,

  /// ADB does not list the device at all.
  deviceNotFound,

  /// The scrcpy server could not be launched on the device.
  serverStartFailed,
}

/// Thrown by `StreamingRepository.startSession` when streaming cannot start.
class StreamStartException implements Exception {
  const StreamStartException(this.failure, {required this.deviceSerial});

  final StreamStartFailure failure;
  final String deviceSerial;

  @override
  String toString() => 'StreamStartException(${failure.name}, $deviceSerial)';
}
