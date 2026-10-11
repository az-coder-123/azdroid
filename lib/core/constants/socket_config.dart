/// Network and socket configuration constants for streaming and control channels.
class SocketConfig {
  const SocketConfig._();

  /// Default ADB server communication port.
  static const int defaultAdbPort = 5037;

  /// Standard wireless ADB daemon port on Android devices.
  static const int defaultAdbWirelessPort = 5555;

  /// Default port for raw H.264 video stream transmission.
  static const int defaultVideoStreamPort = 27183;

  /// Default port for high-frequency input and control packet transmission.
  static const int defaultControlStreamPort = 27184;

  /// Default port for low-latency audio stream transmission.
  static const int defaultAudioStreamPort = 27185;

  /// Socket connection timeout duration in milliseconds.
  static const Duration connectionTimeout = Duration(seconds: 5);

  /// Heartbeat ping interval for active connections.
  static const Duration heartbeatInterval = Duration(seconds: 2);
}
