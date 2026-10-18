/// Network and socket configuration constants for streaming and control channels.
class SocketConfig {
  const SocketConfig._();

  /// Default ADB server communication port.
  static const int defaultAdbPort = 5037;

  /// Standard wireless ADB daemon port on Android devices.
  static const int defaultAdbWirelessPort = 5555;

  /// Host side of `adb forward` tunnels.
  static const String loopbackHost = '127.0.0.1';

  /// Local port of the scrcpy `adb forward` tunnel. The video, audio, and
  /// control sockets all connect here, in that order.
  static const int defaultVideoStreamPort = 27183;

  /// Socket connection timeout duration in milliseconds.
  static const Duration connectionTimeout = Duration(seconds: 5);

  /// Heartbeat ping interval for active connections.
  static const Duration heartbeatInterval = Duration(seconds: 2);
}
