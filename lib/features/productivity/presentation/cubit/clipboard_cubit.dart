import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/productivity/domain/entities/clipboard_item_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/domain/services/clipboard_sync_daemon.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_state.dart';

/// Cubit managing bidirectional clipboard synchronization and its background daemon.
class ClipboardCubit extends Cubit<ClipboardState> {
  ClipboardCubit({
    required this.repository,
    this.autoResetDuration = const Duration(seconds: 4),
    this.daemonBuilder,
  }) : super(const ClipboardInitial());

  final ClipboardRepository repository;
  final Duration? autoResetDuration;
  final ClipboardSyncDaemon Function(ClipboardRepository, String)?
  daemonBuilder;

  ClipboardSyncDaemon? _daemon;
  Timer? _autoResetTimer;

  /// Starts real-time bidirectional background sync daemon.
  void startPeriodicSync(String deviceSerial) {
    stopPeriodicSync();
    if (!state.autoSyncEnabled) return;

    final builder = daemonBuilder;
    _daemon = builder != null
        ? builder(repository, deviceSerial)
        : ClipboardSyncDaemon(
            repository: repository,
            deviceSerial: deviceSerial,
            onSynced: _handleDaemonSynced,
            onError: (err) => AppLogger.debug('Clipboard daemon error: $err'),
          );

    _daemon?.start();
  }

  /// Cancels active auto-sync polling daemon.
  void stopPeriodicSync() {
    _daemon?.stop();
    _daemon = null;
  }

  /// Toggles automatic background synchronization on or off.
  void toggleAutoSync(String deviceSerial) {
    final newEnabled = !state.autoSyncEnabled;
    emit(ClipboardInitial(autoSyncEnabled: newEnabled));

    if (newEnabled) {
      startPeriodicSync(deviceSerial);
    } else {
      stopPeriodicSync();
    }
  }

  /// Resets state back to initial idle without changing autoSyncEnabled.
  void reset() {
    _autoResetTimer?.cancel();
    emit(ClipboardInitial(autoSyncEnabled: state.autoSyncEnabled));
  }

  void _handleDaemonSynced(ClipboardItemEntity item) {
    if (isClosed) return;
    emit(
      ClipboardSynced(lastItem: item, autoSyncEnabled: state.autoSyncEnabled),
    );
    _scheduleAutoReset();
  }

  void _scheduleAutoReset() {
    if (autoResetDuration == null) return;
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(autoResetDuration!, () {
      if (!isClosed && state is ClipboardSynced) {
        emit(ClipboardInitial(autoSyncEnabled: state.autoSyncEnabled));
      }
    });
  }

  /// Manually synchronizes current macOS pasteboard text to Android.
  Future<void> syncHostToDevice(String deviceSerial) async {
    emit(
      ClipboardSyncing(
        direction: 'Mac ➔ Android',
        autoSyncEnabled: state.autoSyncEnabled,
      ),
    );

    try {
      final hostText = await repository.getHostClipboard();
      if (hostText == null || hostText.isEmpty) {
        if (!isClosed) {
          emit(
            ClipboardError(
              errorMessage: 'macOS clipboard is empty.',
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
        }
        return;
      }

      final success = await repository.setDeviceClipboard(
        deviceSerial,
        hostText,
      );

      if (success) {
        _daemon?.recordHostSync(hostText);
        if (!isClosed) {
          final item = ClipboardItemEntity(
            text: hostText,
            source: ClipboardSource.host,
            timestamp: DateTime.now(),
          );
          emit(
            ClipboardSynced(
              lastItem: item,
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
          _scheduleAutoReset();
        }
      } else {
        if (!isClosed) {
          emit(
            ClipboardError(
              errorMessage: 'Failed to write clipboard to Android device.',
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to sync host to device clipboard',
        error: e,
        stackTrace: stack,
      );
      if (!isClosed) {
        emit(
          ClipboardError(
            errorMessage: 'Sync error: $e',
            autoSyncEnabled: state.autoSyncEnabled,
          ),
        );
      }
    }
  }

  /// Manually copies the active Android clipboard text into macOS pasteboard.
  Future<void> syncDeviceToHost(String deviceSerial) async {
    emit(
      ClipboardSyncing(
        direction: 'Android ➔ Mac',
        autoSyncEnabled: state.autoSyncEnabled,
      ),
    );

    try {
      final deviceText = await repository.getDeviceClipboard(deviceSerial);
      if (deviceText == null || deviceText.isEmpty) {
        if (!isClosed) {
          emit(
            ClipboardError(
              errorMessage: 'Android clipboard is empty or unreadable.',
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
        }
        return;
      }

      await repository.setHostClipboard(deviceText);
      _daemon?.recordDeviceSync(deviceText);

      if (!isClosed) {
        final item = ClipboardItemEntity(
          text: deviceText,
          source: ClipboardSource.device,
          timestamp: DateTime.now(),
        );
        emit(
          ClipboardSynced(
            lastItem: item,
            autoSyncEnabled: state.autoSyncEnabled,
          ),
        );
        _scheduleAutoReset();
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to sync device to host clipboard',
        error: e,
        stackTrace: stack,
      );
      if (!isClosed) {
        emit(
          ClipboardError(
            errorMessage: 'Sync error: $e',
            autoSyncEnabled: state.autoSyncEnabled,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _autoResetTimer?.cancel();
    _daemon?.dispose();
    return super.close();
  }
}
