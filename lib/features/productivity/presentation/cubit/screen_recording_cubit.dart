import 'dart:async';

import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing screen recording sessions, timers, and output artifacts.
class ScreenRecordingCubit extends Cubit<ScreenRecordingState> {
  ScreenRecordingCubit({required this.repository, required this._fileLauncher})
    : super(const ScreenRecordingInitial());

  final ScreenRecordingRepository repository;
  final HostFileLauncher _fileLauncher;

  /// Reveals in the OS file manager the saved recording file at [filePath].
  Future<void> revealFile(String filePath) => _fileLauncher.reveal(filePath);

  /// Opens the saved recording file at [filePath] with its default macOS app.
  Future<void> openFile(String filePath) => _fileLauncher.open(filePath);
  Timer? _tickerTimer;
  Timer? _countdownTimer;

  /// Enters preparation state, showing setup actions before recording.
  void prepareRecording(String deviceSerial) {
    if (state is ScreenRecordingActive || state is ScreenRecordingFinalizing) {
      return;
    }
    if (state is ScreenRecordingPreparing) {
      emit(const ScreenRecordingInitial());
    } else {
      emit(ScreenRecordingPreparing(deviceSerial: deviceSerial));
    }
  }

  /// Toggles whether 3-second countdown is enabled in preparation state.
  void toggleCountdown() {
    if (state is ScreenRecordingPreparing) {
      final prep = state as ScreenRecordingPreparing;
      emit(prep.copyWith(countdownEnabled: !prep.countdownEnabled));
    }
  }

  /// Cancels preparation or countdown and returns to initial state.
  void cancelPreparation() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    emit(const ScreenRecordingInitial());
  }

  /// Initiates recording with optional 3-second countdown.
  void startWithCountdown(
    String deviceSerial, {
    bool? withCountdown,
    int? bitrateBps,
    int? timeLimitSeconds,
  }) {
    final useCountdown =
        withCountdown ??
        (state is ScreenRecordingPreparing
            ? (state as ScreenRecordingPreparing).countdownEnabled
            : true);

    if (!useCountdown) {
      startRecording(
        deviceSerial,
        bitrateBps: bitrateBps,
        timeLimitSeconds: timeLimitSeconds,
      );
      return;
    }

    _countdownTimer?.cancel();
    int remaining = 3;
    emit(
      ScreenRecordingCountdown(
        deviceSerial: deviceSerial,
        remainingSeconds: remaining,
      ),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining > 0) {
        emit(
          ScreenRecordingCountdown(
            deviceSerial: deviceSerial,
            remainingSeconds: remaining,
          ),
        );
      } else {
        timer.cancel();
        _countdownTimer = null;
        startRecording(
          deviceSerial,
          bitrateBps: bitrateBps,
          timeLimitSeconds: timeLimitSeconds,
        );
      }
    });
  }

  /// Starts a screen recording session on the target Android device immediately.
  Future<void> startRecording(
    String deviceSerial, {
    int? bitrateBps,
    int? timeLimitSeconds,
  }) async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (state is ScreenRecordingActive || state is ScreenRecordingFinalizing) {
      return;
    }

    try {
      final remoteTempPath = await repository.startRecording(
        deviceSerial: deviceSerial,
        bitrateBps: bitrateBps,
        timeLimitSeconds: timeLimitSeconds,
      );

      final startedAt = DateTime.now();
      emit(
        ScreenRecordingActive(
          deviceSerial: deviceSerial,
          remoteTempPath: remoteTempPath,
          startedAt: startedAt,
        ),
      );

      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state is ScreenRecordingActive) {
          final active = state as ScreenRecordingActive;
          final updated = active.copyWith(
            duration: Duration(seconds: timer.tick),
          );
          emit(updated);

          // Android screenrecord hard limit safeguard (180s)
          if (timer.tick >= (timeLimitSeconds ?? 180)) {
            stopRecording();
          }
        }
      });
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to start screen recording on $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      emit(ScreenRecordingFailure(e.toString()));
    }
  }

  /// Stops the current active recording and pulls the MP4 file to host.
  Future<void> stopRecording({String? customSaveDirectory}) async {
    if (state is! ScreenRecordingActive) return;

    _tickerTimer?.cancel();
    _tickerTimer = null;

    final active = state as ScreenRecordingActive;
    emit(const ScreenRecordingFinalizing());

    try {
      final recording = await repository.stopRecording(
        deviceSerial: active.deviceSerial,
        remoteTempPath: active.remoteTempPath,
        duration: active.duration,
        customSaveDirectory: customSaveDirectory,
      );

      if (recording != null) {
        emit(ScreenRecordingSuccess(recording));
      } else {
        emit(const ScreenRecordingFailure('No recording video data received'));
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to stop screen recording on ${active.deviceSerial}',
        error: e,
        stackTrace: stack,
      );
      emit(ScreenRecordingFailure(e.toString()));
    }
  }

  /// Cancels an ongoing recording session or preparation without transferring.
  Future<void> cancelRecording() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _tickerTimer?.cancel();
    _tickerTimer = null;

    if (state is ScreenRecordingActive) {
      final active = state as ScreenRecordingActive;
      emit(const ScreenRecordingInitial());
      try {
        await repository.cancelRecording(
          deviceSerial: active.deviceSerial,
          remoteTempPath: active.remoteTempPath,
        );
      } catch (e) {
        AppLogger.debug('Cancel recording failed: $e');
      }
      return;
    }

    emit(const ScreenRecordingInitial());
  }

  /// Resets state back to [ScreenRecordingInitial].
  void reset() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _tickerTimer?.cancel();
    _tickerTimer = null;
    emit(const ScreenRecordingInitial());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _tickerTimer?.cancel();
    if (state is ScreenRecordingActive) {
      final active = state as ScreenRecordingActive;
      repository.cancelRecording(
        deviceSerial: active.deviceSerial,
        remoteTempPath: active.remoteTempPath,
      );
    }
    return super.close();
  }
}
