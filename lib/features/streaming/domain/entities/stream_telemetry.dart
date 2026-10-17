import 'package:equatable/equatable.dart';

/// Health of the video stream as measured by the native decoder.
enum StreamHealth {
  /// Waiting for the socket and the stream header.
  connecting,

  /// Header received; frames are being decoded.
  live,

  /// No video ever arrived (no server, bad header, decoder failure).
  failed,

  /// The stream started, then closed by itself (device disconnected).
  ended;

  /// Whether the session can no longer recover on its own.
  bool get isTerminal => this == failed || this == ended;
}

/// Measured stream performance over the last sampling interval.
///
/// Rates are `null` until two samples exist; [latencyMs] is also `null` when
/// no frame was decoded in the interval.
class StreamTelemetry extends Equatable {
  const StreamTelemetry({
    required this.health,
    this.fps,
    this.bitrateMbps,
    this.latencyMs,
    this.videoWidth,
    this.videoHeight,
  });

  final StreamHealth health;

  /// Decoded frames per second.
  final double? fps;

  /// Received video data rate in megabits per second.
  final double? bitrateMbps;

  /// Average host processing time per frame (packet received → frame
  /// published), in milliseconds. Excludes device encode and network time.
  final double? latencyMs;

  /// Current decoded video size in pixels; changes when the device rotates.
  /// `null` until the native side knows it.
  final int? videoWidth;
  final int? videoHeight;

  /// Returns a copy with the decoded video size, ignoring unknown (0) sizes.
  StreamTelemetry withVideoSize(int width, int height) {
    if (width <= 0 || height <= 0) return this;
    return StreamTelemetry(
      health: health,
      fps: fps,
      bitrateMbps: bitrateMbps,
      latencyMs: latencyMs,
      videoWidth: width,
      videoHeight: height,
    );
  }

  @override
  List<Object?> get props => [
    health,
    fps,
    bitrateMbps,
    latencyMs,
    videoWidth,
    videoHeight,
  ];
}
