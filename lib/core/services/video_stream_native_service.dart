import 'package:desk_droid/core/models/native_stream_stats.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/video_decoder_unavailable_exception.dart';
import 'package:flutter/services.dart';

/// Abstract contract for native video streaming and texture lifecycle governance.
abstract class IVideoStreamNativeService {
  /// Initiates hardware decoding on the native platform and returns the allocated Flutter texture ID.
  ///
  /// Throws [VideoDecoderUnavailableException] when the host has no video
  /// decoder; other failures return `null`.
  Future<int?> startStream({String host = '127.0.0.1', int port = 27183});

  /// Terminates the native hardware decompression session and closes the TCP stream.
  Future<void> stopStream();

  /// Retrieves the decoded video frame dimensions (width and height).
  Future<Map<String, int>> getDimensions();

  /// Reads the stream state and cumulative counters, or `null` when the
  /// native side cannot report them.
  Future<NativeStreamStats?> getStats();
}

/// Production implementation of the `com.azdroid/video_stream` channel.
///
/// Served by `macos/Runner/ScrcpyStreamPlugin.swift` and
/// `windows/scrcpy_stream/` (see docs/native-video-contract.md).
class VideoStreamNativeService implements IVideoStreamNativeService {
  VideoStreamNativeService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.azdroid/video_stream');

  final MethodChannel _channel;

  @override
  Future<int?> startStream({
    String host = '127.0.0.1',
    int port = 27183,
  }) async {
    try {
      final result = await _channel.invokeMethod<int>('startStream', {
        'host': host,
        'port': port,
      });
      AppLogger.info('Native video stream started with textureId: $result');
      return result;
    } on PlatformException catch (e, stack) {
      if (e.code == VideoDecoderUnavailableException.errorCode) {
        AppLogger.warning('No video decoder on this computer: ${e.message}');
        throw VideoDecoderUnavailableException(e.message ?? e.code);
      }
      AppLogger.warning(
        'Failed to start native video stream',
        error: e,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to start native video stream',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<void> stopStream() async {
    try {
      await _channel.invokeMethod<void>('stopStream');
      AppLogger.info('Native video stream stopped successfully');
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to stop native video stream',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<Map<String, int>> getDimensions() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDimensions',
      );
      if (result != null) {
        return {
          'width': (result['width'] as num?)?.toInt() ?? 0,
          'height': (result['height'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (e) {
      AppLogger.debug('Failed to get native stream dimensions: $e');
    }
    return {'width': 0, 'height': 0};
  }

  @override
  Future<NativeStreamStats?> getStats() async {
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getStats',
      );
      return result == null ? null : NativeStreamStats.fromMap(result);
    } on MissingPluginException {
      // Older native builds have no getStats; telemetry stays unknown.
      return null;
    } on PlatformException catch (e) {
      AppLogger.debug('Failed to get native stream stats: $e');
      return null;
    }
  }
}
