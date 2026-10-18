import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/mirroring_preferences_repository.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_start_failure_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_reconfigurator.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_telemetry_tracker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing the display mirroring session lifecycle, viewport controls, and navigation input.
class StreamingCubit extends Cubit<StreamingState>
    with StreamingTelemetryTracker, StreamingReconfigurator {
  StreamingCubit({required this.repository, required this.preferences})
    : super(const StreamingInitial());

  @override
  final StreamingRepository repository;

  @override
  final MirroringPreferencesRepository preferences;

  /// Starts a low-latency video streaming session with the specified [device].
  Future<void> startSession(
    DeviceEntity device, {
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
  }) async {
    emit(StreamingStarting(device: device));
    try {
      final saved = await preferences.load();
      final session = await repository.startSession(
        device,
        maxFps: maxFps,
        bitrateMbps: bitrateMbps,
        turnScreenOff: turnScreenOff,
        stayAwake: saved.stayAwake,
      );
      emit(StreamingActive(session: session));
      startTelemetry();
    } on StreamStartException catch (error) {
      AppLogger.warning('Mirroring session not started: $error');
      emit(StreamingError(message: error.failure.messageFor(device.name)));
    } catch (e) {
      emit(StreamingError(message: 'Failed to start mirroring session: $e'));
    }
  }

  /// Stops and cleans up the active streaming session.
  Future<void> stopSession() async {
    await stopTelemetry();
    final currentState = state;
    if (currentState is StreamingActive) {
      try {
        await repository.stopSession(currentState.session.sessionId);
      } catch (e, stack) {
        AppLogger.warning(
          'Error while stopping streaming session',
          error: e,
          stackTrace: stack,
        );
      }
    }
    if (!isClosed) {
      emit(const StreamingInitial());
    }
  }

  @override
  Future<void> close() async {
    await stopTelemetry();
    final currentState = state;
    if (currentState is StreamingActive) {
      try {
        await repository.stopSession(currentState.session.sessionId);
      } catch (e, stack) {
        AppLogger.warning(
          'Error while cleaning up streaming session on close',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return super.close();
  }

  /// Toggles physical device screen display on/off.
  Future<void> toggleScreenOff() async {
    final currentState = state;
    if (currentState is StreamingActive) {
      final newScreenOff = !currentState.session.isScreenOff;
      await repository.toggleScreenOff(
        currentState.session.sessionId,
        newScreenOff,
      );
      emit(
        currentState.copyWith(
          session: currentState.session.copyWith(isScreenOff: newScreenOff),
        ),
      );
    }
  }

  /// Toggles visibility of the floating HUD toolbar overlay.
  void toggleHudVisibility() {
    final currentState = state;
    if (currentState is StreamingActive) {
      emit(currentState.copyWith(isHudVisible: !currentState.isHudVisible));
    }
  }

  /// Cycles rotation of the viewport display by 90 degrees clockwise.
  void rotateScreen() {
    final currentState = state;
    if (currentState is StreamingActive) {
      final newRotation = (currentState.rotationDegrees + 90) % 360;
      emit(currentState.copyWith(rotationDegrees: newRotation));
    }
  }

  /// Injects the Android system Back navigation action.
  Future<void> sendBack() async {
    final currentState = state;
    if (currentState is StreamingActive) {
      await repository.sendNavigationKey(
        currentState.session.sessionId,
        AndroidKeyCodes.keycodeBack,
      );
    }
  }

  /// Injects the Android system Home navigation action.
  Future<void> sendHome() async {
    final currentState = state;
    if (currentState is StreamingActive) {
      await repository.sendNavigationKey(
        currentState.session.sessionId,
        AndroidKeyCodes.keycodeHome,
      );
    }
  }

  /// Injects the Android system App Switcher / Recent Apps action.
  Future<void> sendAppSwitch() async {
    final currentState = state;
    if (currentState is StreamingActive) {
      await repository.sendNavigationKey(
        currentState.session.sessionId,
        AndroidKeyCodes.keycodeAppSwitch,
      );
    }
  }
}
