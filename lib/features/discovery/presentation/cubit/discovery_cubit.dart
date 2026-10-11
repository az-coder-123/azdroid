import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';

/// Cubit managing the device scanning, auto-discovery daemon, and connection state.
class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit({required this.repository}) : super(const DiscoveryInitial());

  final DeviceDiscoveryRepository repository;
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
    } catch (e) {
      emit(DiscoveryError(message: 'Failed to scan for devices: $e'));
    }
  }

  /// Attempts to connect to a specific [device].
  Future<void> connect(DeviceEntity device) async {
    try {
      final success = await repository.connectDevice(device);
      if (success) {
        await scanDevices();
      } else {
        emit(
          const DiscoveryError(
            message: 'Unable to connect to the specified device. Check if port is accessible.',
          ),
        );
      }
    } catch (e) {
      emit(DiscoveryError(message: 'Connection error: $e'));
    }
  }

  /// Disconnects from an active device session.
  Future<void> disconnect(String deviceId) async {
    try {
      await repository.disconnectDevice(deviceId);
      await scanDevices();
    } catch (e) {
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
        await scanDevices();
      } else {
        emit(
          DiscoveryError(
            message:
                'Failed to connect to $ipAddress:$port. Ensure Wireless Debugging is on.',
          ),
        );
      }
    } catch (e) {
      emit(DiscoveryError(message: 'Manual connection error: $e'));
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
