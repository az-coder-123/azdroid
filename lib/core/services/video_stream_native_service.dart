import 'package:flutter/services.dart';
import 'package:wifi_desk/core/services/app_logger.dart';

/// Abstract contract for native video streaming and texture lifecycle governance.
abstract class IVideoStreamNativeService {
  /// Initiates hardware decoding on the native platform and returns the allocated Flutter texture ID.
  Future<int?> startStream({String host = '127.0.0.1', int port = 27183});

  /// Terminates the native hardware decompression session and closes the TCP stream.
  Future<void> stopStream();

  /// Retrieves the decoded video frame dimensions (width and height).
  Future<Map<String, int>> getDimensions();
}

/// Production implementation communicating with macOS Runner via platform channel.
class VideoStreamNativeService implements IVideoStreamNativeService {
  VideoStreamNativeService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.wifidesk/video_stream');

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
}
