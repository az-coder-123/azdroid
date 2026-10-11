import 'package:equatable/equatable.dart';

/// Domain entity representing real-time system status shown in the macOS Menu Bar.
class MenuBarStatusEntity extends Equatable {
  const MenuBarStatusEntity({
    this.activeDeviceName,
    this.batteryLevel,
    this.latencyMs,
    this.fps,
    this.isWindowVisible = true,
    this.discoveredDeviceCount = 0,
  });

  /// Name of the currently mirrored Android device (if any).
  final String? activeDeviceName;

  /// Current battery percentage of the active device (0-100).
  final int? batteryLevel;

  /// Measured glass-to-glass latency in milliseconds.
  final int? latencyMs;

  /// Measured video frame rate (FPS).
  final int? fps;

  /// Whether the main mirroring application window is currently visible on macOS.
  final bool isWindowVisible;

  /// Total count of available Android devices on the local Wi-Fi network.
  final int discoveredDeviceCount;

  MenuBarStatusEntity copyWith({
    String? activeDeviceName,
    int? batteryLevel,
    int? latencyMs,
    int? fps,
    bool? isWindowVisible,
    int? discoveredDeviceCount,
  }) {
    return MenuBarStatusEntity(
      activeDeviceName: activeDeviceName ?? this.activeDeviceName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      latencyMs: latencyMs ?? this.latencyMs,
      fps: fps ?? this.fps,
      isWindowVisible: isWindowVisible ?? this.isWindowVisible,
      discoveredDeviceCount:
          discoveredDeviceCount ?? this.discoveredDeviceCount,
    );
  }

  @override
  List<Object?> get props => [
    activeDeviceName,
    batteryLevel,
    latencyMs,
    fps,
    isWindowVisible,
    discoveredDeviceCount,
  ];
}
