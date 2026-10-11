import 'package:equatable/equatable.dart';
import 'package:wifi_desk/core/constants/audio_constants.dart';

/// Domain entity representing an active low-latency audio stream session.
class AudioStreamEntity extends Equatable {
  const AudioStreamEntity({
    required this.deviceId,
    this.isEnabled = true,
    this.isMuted = false,
    this.volume = AudioConstants.defaultVolume,
    this.codec = AudioConstants.defaultAudioCodec,
    this.sampleRate = AudioConstants.defaultSampleRate,
    this.channels = AudioConstants.defaultChannels,
    this.latencyMs = 15,
  });

  /// Associated Android hardware serial or IP endpoint.
  final String deviceId;

  /// Whether audio streaming is currently running.
  final bool isEnabled;

  /// Whether audio output is muted on host.
  final bool isMuted;

  /// Volume level between 0.0 and 1.0.
  final double volume;

  /// Audio codec name (opus, aac, raw).
  final String codec;

  /// Sample rate in Hertz (e.g. 48000).
  final int sampleRate;

  /// Channel count (1 for Mono, 2 for Stereo).
  final int channels;

  /// Glass-to-ear audio latency in milliseconds.
  final int latencyMs;

  AudioStreamEntity copyWith({
    String? deviceId,
    bool? isEnabled,
    bool? isMuted,
    double? volume,
    String? codec,
    int? sampleRate,
    int? channels,
    int? latencyMs,
  }) {
    return AudioStreamEntity(
      deviceId: deviceId ?? this.deviceId,
      isEnabled: isEnabled ?? this.isEnabled,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      codec: codec ?? this.codec,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    isEnabled,
    isMuted,
    volume,
    codec,
    sampleRate,
    channels,
    latencyMs,
  ];
}
