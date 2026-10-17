import 'package:desk_droid/core/constants/socket_config.dart';

/// Contract for managing `adb forward` TCP tunnels between host and device.
///
/// Lives in `core` so features such as audio and streaming can share one
/// tunnel manager without depending on each other.
abstract class AdbPortForwarder {
  /// Forwards host [localPort] to the scrcpy abstract socket on the device.
  Future<bool> setupPortForward({
    required String deviceSerial,
    int localPort = SocketConfig.defaultVideoStreamPort,
  });

  /// Removes the tunnel previously created for [localPort].
  Future<bool> removePortForward({
    required String deviceSerial,
    int localPort = SocketConfig.defaultVideoStreamPort,
  });
}
