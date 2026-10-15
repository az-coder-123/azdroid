import 'package:desk_droid/features/productivity/data/datasources/screen_recording_datasource.dart';
import 'package:desk_droid/features/productivity/domain/entities/screen_recording_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screen_recording_repository.dart';

/// Implementation of [ScreenRecordingRepository] delegating to [ScreenRecordingDatasource].
class ScreenRecordingRepositoryImpl implements ScreenRecordingRepository {
  const ScreenRecordingRepositoryImpl({required this.datasource});

  final ScreenRecordingDatasource datasource;

  @override
  Future<String> startRecording({
    required String deviceSerial,
    int? bitrateBps,
    int? timeLimitSeconds,
  }) {
    return datasource.startRecording(
      deviceSerial: deviceSerial,
      bitrateBps: bitrateBps,
      timeLimitSeconds: timeLimitSeconds,
    );
  }

  @override
  Future<ScreenRecordingEntity?> stopRecording({
    required String deviceSerial,
    required String remoteTempPath,
    required Duration duration,
    String? customSaveDirectory,
  }) {
    return datasource.stopRecording(
      deviceSerial: deviceSerial,
      remoteTempPath: remoteTempPath,
      duration: duration,
      customSaveDirectory: customSaveDirectory,
    );
  }

  @override
  Future<void> cancelRecording({
    required String deviceSerial,
    required String remoteTempPath,
  }) {
    return datasource.cancelRecording(
      deviceSerial: deviceSerial,
      remoteTempPath: remoteTempPath,
    );
  }
}
