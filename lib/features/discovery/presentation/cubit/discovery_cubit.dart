import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';

/// Cubit managing the device scanning and connection state.
class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit({required this.repository}) : super(const DiscoveryInitial());

  final DeviceDiscoveryRepository repository;

  /// Scans for available devices and updates the state.
  Future<void> scanDevices() async {
    emit(const DiscoveryLoading());
    try {
      final devices = await repository.discoverDevices();
      emit(DiscoveryLoaded(devices: devices));
    } catch (e) {
      emit(DiscoveryError(message: 'Failed to scan for devices: $e'));
    }
  }

  /// Attempts to connect to a specific [device].
  Future<void> connect(DeviceEntity device) async {
    try {
      final success = await repository.connectDevice(device);
      if (success) {
        // Refresh the current device list with updated connection status
        await scanDevices();
      } else {
        emit(const DiscoveryError(
            message: 'Unable to connect to the specified device.'));
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
}
