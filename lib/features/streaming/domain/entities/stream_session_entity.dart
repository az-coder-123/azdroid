import 'package:equatable/equatable.dart';

/// Entity representing an active screen streaming session.
class StreamSessionEntity extends Equatable {
  const StreamSessionEntity({
    required this.sessionId,
    required this.deviceId,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrateMbps,
    this.textureId,
    this.isAudioEnabled = false,
  });

  /// Unique session identifier.
  final String sessionId;

  /// Target Android device identifier.
  final String deviceId;

  /// Stream frame width in pixels.
  final int width;

  /// Stream frame height in pixels.
  final int height;

  /// Target frame rate (e.g., 60 or 120 FPS).
  final int fps;

  /// Video bitrate in megabits per second.
  final int bitrateMbps;

  /// Flutter Native Texture identifier allocated by the macOS runner engine.
  final int? textureId;

  /// Whether audio forwarding is active for this session.
  final bool isAudioEnabled;

  @override
  List<Object?> get props => [
        sessionId,
        deviceId,
        width,
        height,
        fps,
        bitrateMbps,
        textureId,
        isAudioEnabled,
      ];
}
