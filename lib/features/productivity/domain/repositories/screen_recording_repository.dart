import 'package:desk_droid/features/productivity/domain/entities/screen_recording_entity.dart';

/// Contract for managing Android screen recording lifecycle.
abstract class ScreenRecordingRepository {
  /// Initiates video recording on the target Android device.
  /// Returns the remote temporary file path on `/sdcard/`.
  Future<String> startRecording({
    required String deviceSerial,
    int? bitrateBps,
    int? timeLimitSeconds,
  });

  /// Stops an active recording on the device, transfers the MP4 video to macOS host,
  /// and removes the remote temporary file.
  Future<ScreenRecordingEntity?> stopRecording({
    required String deviceSerial,
    required String remoteTempPath,
    required Duration duration,
    String? customSaveDirectory,
  });

  /// Aborts an active recording without saving the output video to host.
  Future<void> cancelRecording({
    required String deviceSerial,
    required String remoteTempPath,
  });
}
