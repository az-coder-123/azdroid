import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:equatable/equatable.dart';

/// Loading lifecycle of [HostContextState].
enum HostContextStatus { initial, loading, loaded, failure }

/// Host-side context shown across discovery screens and dialogs.
///
/// Holds the Mac's local IPv4 address (used in pairing hints) and the list of
/// recently connected devices.
final class HostContextState extends Equatable {
  const HostContextState({
    this.status = HostContextStatus.initial,
    this.hostIpAddress,
    this.recentDevices = const [],
    this.errorMessage,
  });

  final HostContextStatus status;
  final String? hostIpAddress;
  final List<RecentDevice> recentDevices;
  final String? errorMessage;

  HostContextState copyWith({
    HostContextStatus? status,
    String? hostIpAddress,
    List<RecentDevice>? recentDevices,
    String? errorMessage,
  }) {
    return HostContextState(
      status: status ?? this.status,
      hostIpAddress: hostIpAddress ?? this.hostIpAddress,
      recentDevices: recentDevices ?? this.recentDevices,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hostIpAddress,
    recentDevices,
    errorMessage,
  ];
}
