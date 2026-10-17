import 'dart:async';

import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_health_message.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feeds measured telemetry into [StreamingActive] and ends the session with
/// a clear error when the native video stream is lost.
mixin StreamingTelemetryTracker on Cubit<StreamingState> {
  StreamingRepository get repository;

  StreamSubscription<StreamTelemetry>? _telemetrySubscription;

  /// Starts listening to telemetry for the active session.
  void startTelemetry() {
    unawaited(_telemetrySubscription?.cancel());
    _telemetrySubscription = repository.watchTelemetry().listen(
      _onTelemetry,
      onError: (Object error, StackTrace stack) => AppLogger.warning(
        'Stream telemetry failed',
        error: error,
        stackTrace: stack,
      ),
    );
  }

  /// Stops listening; call before stopping the session or closing the cubit.
  Future<void> stopTelemetry() async {
    final subscription = _telemetrySubscription;
    _telemetrySubscription = null;
    await subscription?.cancel();
  }

  void _onTelemetry(StreamTelemetry telemetry) {
    final current = state;
    if (isClosed || current is! StreamingActive) return;

    final lostMessage = telemetry.health.messageFor(current.session.deviceName);
    if (lostMessage == null) {
      emit(current.copyWith(telemetry: telemetry));
    } else {
      AppLogger.warning(
        'Video stream ${telemetry.health.name} for ${current.session.deviceId}',
      );
      unawaited(endSessionWithError(current, lostMessage));
    }
  }

  /// Stops a session that cannot continue and shows [message].
  Future<void> endSessionWithError(
    StreamingActive failed,
    String message,
  ) async {
    AppLogger.warning('Ending session ${failed.session.sessionId}: $message');
    await stopTelemetry();
    try {
      await repository.stopSession(failed.session.sessionId);
    } catch (e, stack) {
      AppLogger.warning(
        'Error while stopping a failed streaming session',
        error: e,
        stackTrace: stack,
      );
    }
    if (!isClosed) emit(StreamingError(message: message));
  }
}
