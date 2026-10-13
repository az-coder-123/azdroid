import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';

/// Cubit managing screen recording sessions, timers, and output artifacts.
class ScreenRecordingCubit extends Cubit<ScreenRecordingState> {
  ScreenRecordingCubit({required this.repository})
    : super(const ScreenRecordingInitial());

  final ScreenRecordingRepository repository;
  Timer? _tickerTimer;

  /// Starts a screen recording session on the target Android device.
  Future<void> startRecording(
    String deviceSerial, {
    int? bitrateBps,
    int? timeLimitSeconds,
  }) async {
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

  /// Cancels an ongoing recording without transferring to host.
  Future<void> cancelRecording() async {
    if (state is! ScreenRecordingActive) return;

    _tickerTimer?.cancel();
    _tickerTimer = null;

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
  }

  /// Resets state back to [ScreenRecordingInitial].
  void reset() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    emit(const ScreenRecordingInitial());
  }

  @override
  Future<void> close() {
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
