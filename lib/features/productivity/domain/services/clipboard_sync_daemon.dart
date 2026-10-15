import 'dart:async';

import 'package:desk_droid/core/constants/productivity_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/productivity/domain/entities/clipboard_item_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';

/// Lightweight background daemon monitoring macOS and Android clipboards
/// for real-time bidirectional synchronization with echo-loop prevention.
class ClipboardSyncDaemon {
  ClipboardSyncDaemon({
    required this.repository,
    required this.deviceSerial,
    this.interval = const Duration(
      seconds: ProductivityConstants.clipboardSyncIntervalSeconds,
    ),
    this.onSynced,
    this.onError,
  });

  final ClipboardRepository repository;
  final String deviceSerial;
  final Duration interval;
  final void Function(ClipboardItemEntity item)? onSynced;
  final void Function(String errorMessage)? onError;

  Timer? _timer;
  bool _isProcessing = false;

  String? _lastHostText;
  String? _lastDeviceText;

  /// Whether the daemon is actively running.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Starts the periodic background polling daemon.
  void start() {
    stop();
    _timer = Timer.periodic(interval, (_) => tick());
  }

  /// Stops the background daemon.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Manually synchronizes host text cache to prevent echo loops on external manual sync.
  void recordHostSync(String text) {
    _lastHostText = text;
    _lastDeviceText = text;
  }

  /// Manually synchronizes device text cache to prevent echo loops on external manual sync.
  void recordDeviceSync(String text) {
    _lastDeviceText = text;
    _lastHostText = text;
  }

  /// Single execution tick evaluating both clipboard sources.
  Future<void> tick() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _syncHostToDevice();
      await _syncDeviceToHost();
    } catch (e, stack) {
      AppLogger.debug('Clipboard daemon tick error: $e\n$stack');
      onError?.call('Clipboard sync tick error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _syncHostToDevice() async {
    final currentHost = await repository.getHostClipboard();
    if (currentHost == null || currentHost.isEmpty) return;

    // Skip if unchanged or was just synced from Android
    if (currentHost == _lastHostText || currentHost == _lastDeviceText) {
      return;
    }

    _lastHostText = currentHost;
    final success = await repository.setDeviceClipboard(
      deviceSerial,
      currentHost,
    );

    if (success) {
      _lastDeviceText = currentHost;
      onSynced?.call(
        ClipboardItemEntity(
          text: currentHost,
          source: ClipboardSource.host,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _syncDeviceToHost() async {
    final currentDevice = await repository.getDeviceClipboard(deviceSerial);
    if (currentDevice == null || currentDevice.isEmpty) return;

    // Skip if unchanged or was just synced from Host
    if (currentDevice == _lastDeviceText || currentDevice == _lastHostText) {
      return;
    }

    _lastDeviceText = currentDevice;
    await repository.setHostClipboard(currentDevice);
    _lastHostText = currentDevice;

    onSynced?.call(
      ClipboardItemEntity(
        text: currentDevice,
        source: ClipboardSource.device,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Disposes active timers and clears state.
  void dispose() {
    stop();
  }
}
