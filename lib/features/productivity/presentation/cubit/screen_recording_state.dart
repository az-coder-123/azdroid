import 'package:equatable/equatable.dart';
import 'package:desk_droid/features/productivity/domain/entities/screen_recording_entity.dart';

/// Base state for device screen recording lifecycle.
sealed class ScreenRecordingState extends Equatable {
  const ScreenRecordingState();

  @override
  List<Object?> get props => [];
}

/// Initial resting state when no recording is in progress.
final class ScreenRecordingInitial extends ScreenRecordingState {
  const ScreenRecordingInitial();
}

/// Preparing state when user clicked record, showing countdown toggle and start action.
final class ScreenRecordingPreparing extends ScreenRecordingState {
  const ScreenRecordingPreparing({
    required this.deviceSerial,
    this.countdownEnabled = true,
  });

  final String deviceSerial;
  final bool countdownEnabled;

  ScreenRecordingPreparing copyWith({
    String? deviceSerial,
    bool? countdownEnabled,
  }) {
    return ScreenRecordingPreparing(
      deviceSerial: deviceSerial ?? this.deviceSerial,
      countdownEnabled: countdownEnabled ?? this.countdownEnabled,
    );
  }

  @override
  List<Object?> get props => [deviceSerial, countdownEnabled];
}

/// Active countdown state ticking down before screenrecord process starts.
final class ScreenRecordingCountdown extends ScreenRecordingState {
  const ScreenRecordingCountdown({
    required this.deviceSerial,
    required this.remainingSeconds,
  });

  final String deviceSerial;
  final int remainingSeconds;

  @override
  List<Object?> get props => [deviceSerial, remainingSeconds];
}

/// Active recording state with live elapsed duration and target device info.
final class ScreenRecordingActive extends ScreenRecordingState {
  const ScreenRecordingActive({
    required this.deviceSerial,
    required this.remoteTempPath,
    required this.startedAt,
    this.duration = Duration.zero,
  });

  final String deviceSerial;
  final String remoteTempPath;
  final DateTime startedAt;
  final Duration duration;

  ScreenRecordingActive copyWith({Duration? duration}) {
    return ScreenRecordingActive(
      deviceSerial: deviceSerial,
      remoteTempPath: remoteTempPath,
      startedAt: startedAt,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
    deviceSerial,
    remoteTempPath,
    startedAt,
    duration,
  ];
}

/// Finalizing state while stopping recording on device and pulling MP4 to host.
final class ScreenRecordingFinalizing extends ScreenRecordingState {
  const ScreenRecordingFinalizing();
}

/// Success state containing the saved video recording artifact.
final class ScreenRecordingSuccess extends ScreenRecordingState {
  const ScreenRecordingSuccess(this.recording);

  final ScreenRecordingEntity recording;

  @override
  List<Object?> get props => [recording];
}

/// Failure state containing error diagnosis.
final class ScreenRecordingFailure extends ScreenRecordingState {
  const ScreenRecordingFailure(this.errorMessage);

  final String errorMessage;

  String get message => errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
