import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/productivity_constants.dart';
import 'package:wifi_desk/features/productivity/domain/entities/clipboard_item_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_state.dart';

/// Cubit managing bidirectional clipboard synchronization between macOS and Android.
class ClipboardCubit extends Cubit<ClipboardState> {
  ClipboardCubit({required this.repository}) : super(const ClipboardInitial());

  final ClipboardRepository repository;
  Timer? _autoSyncTimer;
  String? _lastKnownHostText;

  /// Starts background polling to synchronize new macOS copies to Android.
  void startPeriodicSync(String deviceSerial) {
    _autoSyncTimer?.cancel();
    if (!state.autoSyncEnabled) return;

    _autoSyncTimer = Timer.periodic(
      const Duration(
        seconds: ProductivityConstants.clipboardSyncIntervalSeconds,
      ),
      (_) => _checkAndSyncHostClipboard(deviceSerial),
    );
  }

  /// Cancels active auto-sync polling.
  void stopPeriodicSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Toggles automatic background synchronization on or off.
  void toggleAutoSync(String deviceSerial) {
    final newEnabled = !state.autoSyncEnabled;
    if (newEnabled) {
      emit(ClipboardInitial(autoSyncEnabled: newEnabled));
      startPeriodicSync(deviceSerial);
    } else {
      stopPeriodicSync();
      emit(ClipboardInitial(autoSyncEnabled: newEnabled));
    }
  }

  Future<void> _checkAndSyncHostClipboard(String deviceSerial) async {
    try {
      final currentHost = await repository.getHostClipboard();
      if (currentHost != null &&
          currentHost.isNotEmpty &&
          currentHost != _lastKnownHostText) {
        _lastKnownHostText = currentHost;
        final success = await repository.setDeviceClipboard(
          deviceSerial,
          currentHost,
        );
        if (success && !isClosed) {
          emit(
            ClipboardSynced(
              lastItem: ClipboardItemEntity(
                text: currentHost,
                source: ClipboardSource.host,
                timestamp: DateTime.now(),
              ),
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
        }
      }
    } catch (_) {
      // Background poll silently continues
    }
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
        _lastKnownHostText = hostText;
        if (!isClosed) {
          emit(
            ClipboardSynced(
              lastItem: ClipboardItemEntity(
                text: hostText,
                source: ClipboardSource.host,
                timestamp: DateTime.now(),
              ),
              autoSyncEnabled: state.autoSyncEnabled,
            ),
          );
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
    } catch (e) {
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
      _lastKnownHostText = deviceText;

      if (!isClosed) {
        emit(
          ClipboardSynced(
            lastItem: ClipboardItemEntity(
              text: deviceText,
              source: ClipboardSource.device,
              timestamp: DateTime.now(),
            ),
            autoSyncEnabled: state.autoSyncEnabled,
          ),
        );
      }
    } catch (e) {
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
    _autoSyncTimer?.cancel();
    return super.close();
  }
}
