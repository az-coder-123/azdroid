import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/models/native_audio_stats.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:flutter/services.dart';

/// Native audio player of the mirroring session.
///
/// Streaming opens and closes it (the audio socket must connect between the
/// video and control sockets); the audio feature controls volume and reads
/// its state. Lives in core so neither feature imports the other.
abstract class IAudioStreamNativeService {
  /// Whether this platform has a native audio player. When `false`, the
  /// server must run with `audio=false`, or it would wait for an audio
  /// socket that never connects.
  Future<bool> isAvailable();

  /// Opens the audio socket; `true` once it is connected locally.
  Future<bool> startAudio({String host, int port});

  Future<void> stopAudio();

  /// Playback gain, 0.0 – 1.0. Kept by the native side across sessions.
  Future<void> setVolume(double volume);

  /// Silences playback; kept by the native side across sessions.
  Future<void> setMuted(bool muted);

  /// Current state and counters, or `null` when not readable.
  Future<NativeAudioStats?> getStats();
}

/// Production implementation of the `com.azdroid/audio_stream` channel,
/// served by `macos/Runner/ScrcpyAudioPlugin.swift` and
/// `windows/scrcpy_stream/` (see docs/native-audio-contract.md).
class AudioStreamNativeService implements IAudioStreamNativeService {
  AudioStreamNativeService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.azdroid/audio_stream');

  final MethodChannel _channel;
  bool? _available;

  @override
  Future<bool> isAvailable() async {
    final cached = _available;
    if (cached != null) return cached;
    try {
      return _available =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      AppLogger.info('No native audio player on this platform');
      return _available = false;
    } on PlatformException catch (e) {
      AppLogger.warning('Audio availability check failed', error: e);
      return false;
    }
  }

  @override
  Future<bool> startAudio({
    String host = SocketConfig.loopbackHost,
    int port = SocketConfig.defaultVideoStreamPort,
  }) => _invoke<bool>('startAudio', {
    'host': host,
    'port': port,
  }).then((connected) => connected ?? false);

  @override
  Future<void> stopAudio() => _invoke<bool>('stopAudio');

  @override
  Future<void> setVolume(double volume) =>
      _invoke<bool>('setVolume', {'volume': volume});

  @override
  Future<void> setMuted(bool muted) =>
      _invoke<bool>('setMuted', {'muted': muted});

  @override
  Future<NativeAudioStats?> getStats() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getAudioStats',
      );
      return map == null ? null : NativeAudioStats.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      AppLogger.debug('Audio stats not readable: $e');
      return null;
    }
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e, stack) {
      AppLogger.warning('Audio $method failed', error: e, stackTrace: stack);
      return null;
    }
  }
}
