import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';
import 'package:desk_droid/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/discovery_state.dart';

/// Cubit managing the device scanning, auto-discovery daemon, and connection state.
class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit({required this.repository, this.historyService})
    : super(const DiscoveryInitial());

  final DeviceDiscoveryRepository repository;
  final DeviceHistoryService? historyService;
  Timer? _autoScanTimer;

  /// Scans for available devices and updates the state.
  /// When [silent] is true, avoids switching to full-screen loading state.
  Future<void> scanDevices({bool silent = false}) async {
    final currentState = state;
    if (!silent || currentState is! DiscoveryLoaded) {
      emit(const DiscoveryLoading());
    } else {
      emit(
        DiscoveryLoaded(devices: currentState.devices, isAutoScanning: true),
      );
    }

    try {
      final devices = await repository.discoverDevices();
      emit(DiscoveryLoaded(devices: devices, isAutoScanning: false));
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to scan for devices',
        error: e,
        stackTrace: stack,
      );
      emit(DiscoveryError(message: 'Failed to scan for devices: $e'));
    }
  }

  /// Attempts to connect to a specific [device].
  Future<void> connect(DeviceEntity device) async {
    try {
      final success = await repository.connectDevice(device);
      if (success) {
        historyService?.saveRecentDevice(
          RecentDevice(
            id: device.id,
            name: device.name,
            ipAddress: device.ipAddress,
            port: device.port,
            lastConnected: DateTime.now(),
          ),
        );
        await scanDevices();
      } else {
        emit(
          const DiscoveryError(
            message: 'Unable to connect to the specified device. Check if port is accessible.',
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Connection error to device ${device.id}',
        error: e,
        stackTrace: stack,
      );
      emit(DiscoveryError(message: 'Connection error: $e'));
    }
  }

  /// Disconnects from an active device session.
  Future<void> disconnect(String deviceId) async {
    try {
      await repository.disconnectDevice(deviceId);
      await scanDevices();
    } catch (e, stack) {
      AppLogger.warning(
        'Disconnect error for device $deviceId',
        error: e,
        stackTrace: stack,
      );
      emit(DiscoveryError(message: 'Disconnect error: $e'));
    }
  }

  /// Connects to a target device via manual IP and port input.
  Future<void> manualConnect({
    required String ipAddress,
    required int port,
  }) async {
    emit(const DiscoveryLoading());
    try {
      final success = await repository.manualConnect(
        ipAddress: ipAddress,
        port: port,
      );
      if (success) {
        historyService?.saveRecentDevice(
          RecentDevice(
            id: '$ipAddress:$port',
            name: 'Android Device',
            ipAddress: ipAddress,
            port: port,
            lastConnected: DateTime.now(),
          ),
        );
        await scanDevices();
      } else {
        emit(
          DiscoveryError(
            message:
                'Failed to connect to $ipAddress:$port. Ensure Wireless Debugging is on.',
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Manual connection error to $ipAddress:$port',
        error: e,
        stackTrace: stack,
      );
      emit(DiscoveryError(message: 'Manual connection error: $e'));
    }
  }

  /// Switches an attached USB device to wireless Wi-Fi mode using ADB TCP/IP.
  Future<bool> switchUsbToWifi(DeviceEntity device, {int port = 5555}) async {
    emit(const DiscoveryLoading());
    try {
      final success = await repository.switchUsbToWifi(device.id, port: port);
      if (success) {
        historyService?.saveRecentDevice(
          RecentDevice(
            id: '${device.ipAddress}:$port',
            name: device.name,
            ipAddress: device.ipAddress,
            port: port,
            lastConnected: DateTime.now(),
          ),
        );
      }
      await scanDevices();
      return success;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to switch USB device to Wi-Fi: ${device.id}',
        error: e,
        stackTrace: stack,
      );
      emit(DiscoveryError(message: 'Failed to switch to Wi-Fi: $e'));
      return false;
    }
  }

  /// Starts the periodic discovery daemon.
  void startAutoScan({Duration interval = const Duration(seconds: 5)}) {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(interval, (_) {
      scanDevices(silent: true);
    });
  }

  /// Stops the periodic discovery daemon.
  void stopAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = null;
  }

  @override
  Future<void> close() {
    _autoScanTimer?.cancel();
    return super.close();
  }
}
