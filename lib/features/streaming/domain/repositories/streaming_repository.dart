import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';

/// Contract defining low-latency video streaming and session lifecycle operations.
abstract class StreamingRepository {
  /// Initiates a low-latency video mirroring session with the specified [device].
  Future<StreamSessionEntity> startSession(
    DeviceEntity device, {
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
  });

  /// Terminates an active mirroring session identified by [sessionId].
  Future<void> stopSession(String sessionId);

  /// Toggles physical Android display power off or on during streaming.
  Future<void> toggleScreenOff(String sessionId, bool turnOff);

  /// Dynamically updates video bitrate in Mbps during an active stream.
  Future<void> updateBitrate(String sessionId, int bitrateMbps);

  /// Injects Android navigation keycode actions (Back, Home, AppSwitch).
  Future<void> sendNavigationKey(String sessionId, int keyCode);
}
