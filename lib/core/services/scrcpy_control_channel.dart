import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/app_logger.dart';

/// The scrcpy control socket of the current mirroring session.
///
/// Opened by streaming (after the server accepted the video socket) and used
/// by control to send input. Lives in core so neither feature imports the
/// other. Message bytes come from `ScrcpyControlMessage`.
abstract class ScrcpyControlChannel {
  /// Serial of the device this channel is connected to, or `null`.
  String? get deviceSerial;

  bool get isConnected;

  /// Opens the control socket through the forwarded [port].
  Future<bool> connect({required String deviceSerial, required int port});

  /// Queues [message] for sending. Returns `false` when not connected.
  bool send(Uint8List message);

  /// Sends what is queued (bounded wait), then closes the socket. Safe to
  /// call when already closed.
  Future<void> close();
}

/// [ScrcpyControlChannel] over a loopback TCP socket (`adb forward`).
class SocketScrcpyControlChannel implements ScrcpyControlChannel {
  SocketScrcpyControlChannel({
    this._host = SocketConfig.loopbackHost,
    this._connectTimeout = SocketConfig.connectionTimeout,
  });

  /// Upper bound for sending queued messages on [close].
  static const Duration _flushTimeout = Duration(milliseconds: 500);

  final String _host;
  final Duration _connectTimeout;
  Socket? _socket;
  String? _deviceSerial;

  @override
  String? get deviceSerial => _deviceSerial;

  @override
  bool get isConnected => _socket != null;

  @override
  Future<bool> connect({
    required String deviceSerial,
    required int port,
  }) async {
    await close();
    try {
      final socket = await Socket.connect(
        _host,
        port,
        timeout: _connectTimeout,
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      // Device messages (clipboard, UHID output) are not used; drain them so
      // the server never blocks on a full socket buffer.
      socket.listen(
        (_) {},
        onError: (Object error) => _onClosed(socket, error),
        onDone: () => _onClosed(socket, null),
        cancelOnError: true,
      );
      _socket = socket;
      _deviceSerial = deviceSerial;
      AppLogger.info('scrcpy control channel connected for $deviceSerial');
      return true;
    } on SocketException catch (error) {
      AppLogger.warning('scrcpy control channel failed', error: error);
      return false;
    }
  }

  @override
  bool send(Uint8List message) {
    final socket = _socket;
    if (socket == null) return false;
    socket.add(message);
    return true;
  }

  @override
  Future<void> close() async {
    final socket = _socket;
    _socket = null;
    _deviceSerial = null;
    if (socket == null) return;
    try {
      // A last message (such as "display on") must not be dropped.
      await socket.flush().timeout(_flushTimeout);
    } on Exception catch (error) {
      AppLogger.debug('scrcpy control channel not flushed on close: $error');
    }
    socket.destroy();
  }

  void _onClosed(Socket socket, Object? error) {
    if (!identical(socket, _socket)) return;
    _socket = null;
    _deviceSerial = null;
    if (error != null) {
      AppLogger.warning('scrcpy control channel closed', error: error);
    } else {
      AppLogger.info('scrcpy control channel closed by the server');
    }
  }
}
