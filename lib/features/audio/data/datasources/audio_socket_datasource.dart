import 'dart:async';
import 'dart:io';

import 'package:wifi_desk/core/constants/socket_config.dart';

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
        onError: (_) => disconnect(),
        onDone: () => disconnect(),
        cancelOnError: true,
      );

      return true;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket?.destroy();
    _socket = null;
  }
}
