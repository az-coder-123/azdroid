/// Thrown by `IVideoStreamNativeService.startStream` when the host has no
/// video decoder, for example a Windows N/KN edition without Media
/// Foundation (native error code `DECODER_UNAVAILABLE`).
class VideoDecoderUnavailableException implements Exception {
  const VideoDecoderUnavailableException(this.message);

  /// Native error code sent on the channel.
  static const String errorCode = 'DECODER_UNAVAILABLE';

  /// Native description, for logs.
  final String message;

  @override
  String toString() => 'VideoDecoderUnavailableException: $message';
}
