import 'dart:async';
import 'dart:io';

import 'package:wifi_desk/core/constants/socket_config.dart';
import 'package:wifi_desk/core/services/app_logger.dart';

/// Abstract datasource for connecting to the scrcpy audio streaming TCP socket.
abstract class AudioSocketDatasource {
  /// Establishes connection to the local forwarded audio TCP socket.
  Future<bool> connect({
    String host = '127.0.0.1',
    int port = SocketConfig.defaultAudioStreamPort,
  });

  /// Closes the active audio socket connection.
  Future<void> disconnect();

  /// Stream of raw incoming PCM/Opus audio byte packets.
  Stream<List<int>> get audioPacketStream;

  /// Whether the audio socket is currently connected.
  bool get isConnected;
}

/// Concrete implementation of [AudioSocketDatasource] managing local TCP socket connections.
class AudioSocketDatasourceImpl implements AudioSocketDatasource {
  Socket? _socket;
  StreamController<List<int>>? _streamController;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<List<int>> get audioPacketStream {
    _streamController ??= StreamController<List<int>>.broadcast();
    return _streamController!.stream;
  }

  @override
  Future<bool> connect({
    String host = '127.0.0.1',
    int port = SocketConfig.defaultAudioStreamPort,
  }) async {
    await disconnect();
    _streamController ??= StreamController<List<int>>.broadcast();

    try {
      _socket = await Socket.connect(
        host,
        port,
        timeout: SocketConfig.connectionTimeout,
      );

      _connected = true;
      _socket!.listen(
        (data) {
          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.add(data);
          }
        },
        onError: (e) {
          AppLogger.warning('Audio socket error received: $e');
          disconnect();
        },
        onDone: () => disconnect(),
        cancelOnError: true,
      );

      return true;
    } catch (e, stack) {
      AppLogger.warning(
        'Audio socket connection to $host:$port failed',
        error: e,
        stackTrace: stack,
      );
      _connected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    try {
      await _socket?.close();
    } catch (e) {
      AppLogger.debug('Audio socket close error: $e');
    }
    _socket?.destroy();
    _socket = null;
  }
}
