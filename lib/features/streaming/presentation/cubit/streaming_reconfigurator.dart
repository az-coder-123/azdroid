import 'package:desk_droid/features/streaming/domain/entities/mirroring_preferences.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/domain/repositories/mirroring_preferences_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/pending_stream_change.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_start_failure_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_telemetry_tracker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Changes launch options of the active session (bitrate, stay awake). Each
/// change restarts the video pipeline, shown as [StreamingActive.pendingChange].
mixin StreamingReconfigurator
    on Cubit<StreamingState>, StreamingTelemetryTracker {
  MirroringPreferencesRepository get preferences;

  /// Restarts the video pipeline at [bitrateMbps]. Ignored while another
  /// change is in progress or when the bitrate is unchanged.
  Future<void> updateBitrate(int bitrateMbps) async {
    final current = state;
    if (current is! StreamingActive ||
        current.session.bitrateMbps == bitrateMbps) {
      return;
    }
    await _reconfigure(
      current,
      BitrateChange(bitrateMbps),
      () => repository.updateBitrate(current.session.sessionId, bitrateMbps),
      fallbackError: 'Failed to change the bitrate',
    );
  }

  /// Flips "keep the phone awake", remembers the choice for next sessions,
  /// and restarts the pipeline so the server applies it. Ignored while
  /// another change is in progress.
  Future<void> toggleStayAwake() async {
    final current = state;
    if (current is! StreamingActive || current.isReconfiguring) return;
    final enabled = !current.session.stayAwake;
    await preferences.save(MirroringPreferences(stayAwake: enabled));
    await _reconfigure(
      current,
      StayAwakeChange(enabled: enabled),
      () => repository.updateStayAwake(current.session.sessionId, enabled),
      fallbackError: 'Failed to change the stay-awake setting',
    );
  }

  Future<void> _reconfigure(
    StreamingActive current,
    PendingStreamChange change,
    Future<StreamSessionEntity> Function() restart, {
    required String fallbackError,
  }) async {
    if (current.isReconfiguring) return;
    emit(current.copyWith(pendingChange: change));
    try {
      final session = await restart();
      final latest = state;
      if (!isClosed && latest is StreamingActive) {
        // Keep the measured video size; the restart does not change it.
        final restarted = session.copyWith(
          width: latest.session.width,
          height: latest.session.height,
        );
        emit(latest.copyWith(session: restarted, clearPendingChange: true));
      }
    } on StreamStartException catch (error) {
      await endSessionWithError(
        current,
        error.failure.messageFor(current.session.deviceName),
      );
    } catch (e) {
      await endSessionWithError(current, '$fallbackError: $e');
    }
  }
}
