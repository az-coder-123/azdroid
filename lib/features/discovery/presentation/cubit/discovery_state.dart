import 'package:equatable/equatable.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Base class for all states emitted by [DiscoveryCubit].
sealed class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before any scan has taken place.
final class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

/// State emitted while actively scanning the network or ADB endpoints.
final class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// State emitted when device discovery finishes with a list of found devices.
final class DiscoveryLoaded extends DiscoveryState {
  const DiscoveryLoaded({required this.devices, this.isAutoScanning = false});

  final List<DeviceEntity> devices;
  final bool isAutoScanning;

  @override
  List<Object?> get props => [devices, isAutoScanning];
}

/// State emitted when an error occurs during discovery or connection.
final class DiscoveryError extends DiscoveryState {
  const DiscoveryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
