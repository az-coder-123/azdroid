import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';

/// Contract defining low-latency video streaming and session lifecycle operations.
abstract class StreamingRepository {
  /// Initiates a low-latency video mirroring session with the specified [device].
  ///
  /// Throws `StreamStartException` when the device is not ready (missing,
  /// offline, or unauthorized) or the scrcpy server cannot be launched.
  Future<StreamSessionEntity> startSession(
    DeviceEntity device, {
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
  });

  /// Emits measured stream telemetry about once per second while listened to.
  ///
  /// A terminal [StreamTelemetry.health] (`failed`, `ended`) means the video
  /// stream is gone and the session should be stopped.
  Stream<StreamTelemetry> watchTelemetry();

  /// Terminates an active mirroring session identified by [sessionId].
  Future<void> stopSession(String sessionId);

  /// Toggles physical Android display power off or on during streaming.
  Future<void> toggleScreenOff(String sessionId, bool turnOff);

  /// Changes the video bitrate of the active session to [bitrateMbps].
  ///
  /// scrcpy fixes the bitrate at launch, so this restarts the video pipeline
  /// and returns the session with its new texture. Throws
  /// `StreamStartException` when the restarted server cannot start.
  Future<StreamSessionEntity> updateBitrate(String sessionId, int bitrateMbps);

  /// Injects Android navigation keycode actions (Back, Home, AppSwitch).
  Future<void> sendNavigationKey(String sessionId, int keyCode);
}
