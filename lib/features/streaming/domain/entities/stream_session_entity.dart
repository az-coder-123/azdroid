import 'package:equatable/equatable.dart';

/// Entity representing an active screen streaming session.
class StreamSessionEntity extends Equatable {
  const StreamSessionEntity({
    required this.sessionId,
    required this.deviceId,
    this.deviceName = 'Android Device',
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrateMbps,
    this.textureId,
    this.isAudioEnabled = false,
    this.isConnected = true,
    this.isScreenOff = false,
  });

  /// Placeholder size until the native decoder reports the real one
  /// (a typical 1080p portrait phone).
  static const int placeholderWidth = 1080;
  static const int placeholderHeight = 2400;

  /// Unique session identifier.
  final String sessionId;

  /// Target Android device identifier.
  final String deviceId;

  /// Human-readable device display name.
  final String deviceName;

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

  /// Active connection status flag.
  final bool isConnected;

  /// Whether the physical phone screen is powered off during streaming.
  final bool isScreenOff;

  /// Aspect ratio calculated from width and height.
  double get aspectRatio => height > 0 ? width / height : 9 / 19.5;

  StreamSessionEntity copyWith({
    String? sessionId,
    String? deviceId,
    String? deviceName,
    int? width,
    int? height,
    int? fps,
    int? bitrateMbps,
    int? textureId,
    bool? isAudioEnabled,
    bool? isConnected,
    bool? isScreenOff,
  }) {
    return StreamSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      textureId: textureId ?? this.textureId,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isConnected: isConnected ?? this.isConnected,
      isScreenOff: isScreenOff ?? this.isScreenOff,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    deviceId,
    deviceName,
    width,
    height,
    fps,
    bitrateMbps,
    textureId,
    isAudioEnabled,
    isConnected,
    isScreenOff,
  ];
}
