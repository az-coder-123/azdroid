import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:equatable/equatable.dart';

/// Base class for all states emitted by [StreamingCubit].
sealed class StreamingState extends Equatable {
  const StreamingState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state when no mirroring session is active.
final class StreamingInitial extends StreamingState {
  const StreamingInitial();
}

/// State emitted while initializing the daemon and establishing socket tunnels.
final class StreamingStarting extends StreamingState {
  const StreamingStarting({required this.device});

  final DeviceEntity device;

  @override
  List<Object?> get props => [device];
}

/// Active mirroring state rendering the real-time display viewport.
final class StreamingActive extends StreamingState {
  const StreamingActive({
    required this.session,
    this.isHudVisible = true,
    this.rotationDegrees = 0,
    this.telemetry,
    this.pendingBitrateMbps,
  });

  final StreamSessionEntity session;
  final bool isHudVisible;
  final int rotationDegrees;

  /// Latest measured telemetry, or `null` before the first sample.
  final StreamTelemetry? telemetry;

  /// Bitrate being applied by a pipeline restart, or `null` when idle.
  final int? pendingBitrateMbps;

  bool get isReconfiguring => pendingBitrateMbps != null;

  StreamingActive copyWith({
    StreamSessionEntity? session,
    bool? isHudVisible,
    int? rotationDegrees,
    StreamTelemetry? telemetry,
    int? pendingBitrateMbps,
    bool clearPendingBitrate = false,
  }) {
    return StreamingActive(
      session: session ?? this.session,
      isHudVisible: isHudVisible ?? this.isHudVisible,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      telemetry: telemetry ?? this.telemetry,
      pendingBitrateMbps: clearPendingBitrate
          ? null
          : pendingBitrateMbps ?? this.pendingBitrateMbps,
    );
  }

  @override
  List<Object?> get props => [
    session,
    isHudVisible,
    rotationDegrees,
    telemetry,
    pendingBitrateMbps,
  ];
}

/// State emitted when the active session is temporarily paused.
final class StreamingPaused extends StreamingState {
  const StreamingPaused({required this.session});

  final StreamSessionEntity session;

  @override
  List<Object?> get props => [session];
}

/// State emitted when a fatal streaming or socket error occurs.
final class StreamingError extends StreamingState {
  const StreamingError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
