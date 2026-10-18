import 'package:equatable/equatable.dart';

/// User preferences and streaming fidelity settings.
class AppSettingsEntity extends Equatable {
  const AppSettingsEntity({
    this.maxFps = 60,
    this.bitrateMbps = 8,
    this.turnScreenOff = true,
    this.autoReconnect = true,
    this.audioForwarding = false,
  });

  /// Frame rate cap (30, 60, 90, 120).
  final int maxFps;

  /// Streaming bitrate in Mbps.
  final int bitrateMbps;

  /// Whether to power down the physical phone screen during streaming.
  final bool turnScreenOff;

  /// Automatically attempt reconnection if connection drops.
  final bool autoReconnect;

  /// Forward device audio to macOS speakers.
  final bool audioForwarding;

  AppSettingsEntity copyWith({
    int? maxFps,
    int? bitrateMbps,
    bool? turnScreenOff,
    bool? autoReconnect,
    bool? audioForwarding,
  }) {
    return AppSettingsEntity(
      maxFps: maxFps ?? this.maxFps,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      turnScreenOff: turnScreenOff ?? this.turnScreenOff,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      audioForwarding: audioForwarding ?? this.audioForwarding,
    );
  }

  @override
  List<Object?> get props => [
    maxFps,
    bitrateMbps,
    turnScreenOff,
    autoReconnect,
    audioForwarding,
  ];
}
