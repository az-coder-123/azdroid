import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_scrcpy_jar_locator.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';

/// A control-only scrcpy server session owned by the MCP process: real
/// multi-finger touch with millisecond timing, which `adb shell input`
/// (one finger, 100–300 ms per command) cannot do.
///
/// It runs beside Azdroid's own mirroring session without touching it: its
/// own jar copy, a random session id, no video or audio, and no cleanup
/// process. With no video the server injects the raw coordinates, so
/// events are in pixels of the current screen orientation. Sessions are
/// reused per device and closed after [idleTimeout].
class McpScrcpyTouchSession {
  McpScrcpyTouchSession._(this.serial, this._server, this._socket, this._port);

  static const String remoteJarPath = '/data/local/tmp/azdroid-mcp-scrcpy.jar';
  static const Duration idleTimeout = Duration(minutes: 2);
  static const Duration connectTimeout = Duration(seconds: 8);

  static final Map<String, McpScrcpyTouchSession> _sessions = {};

  final String serial;
  final Process _server;
  final Socket _socket;
  final int _port;
  McpAdbClient? _adb;
  Timer? _idle;
  bool _closed = false;

  bool get isOpen => !_closed;

  /// The open session for [serial], started when needed.
  static Future<McpScrcpyTouchSession> open(
    McpAdbClient adb,
    String serial, {
    McpScrcpyJarLocator? locator,
  }) async {
    final existing = _sessions[serial];
    if (existing != null && existing.isOpen) return existing.._touch();
    final session = await _start(adb, serial, locator ?? McpScrcpyJarLocator());
    _sessions[serial] = session.._adb = adb;
    return session.._touch();
  }

  static Future<McpScrcpyTouchSession> _start(
    McpAdbClient adb,
    String serial,
    McpScrcpyJarLocator locator,
  ) async {
    final adbPath = await adb.resolveAdb();
    final jar = locator.locate();
    if (adbPath == null || jar == null) {
      throw McpUnsupportedOnDeviceException(
        adbPath == null
            ? 'adb was not found on this computer.'
            : 'scrcpy-server.jar was not found next to the server '
                  '(${ScrcpyServerConstants.assetKey}).',
      );
    }
    final push = await adb.run(['-s', serial, 'push', jar, remoteJarPath]);
    if (push.exitCode != 0) {
      throw McpUnsupportedOnDeviceException(
        'Could not copy scrcpy-server to the device: ${push.stderr}'.trim(),
      );
    }
    // A random non-zero id keeps clear of the app's mirroring (scid 0).
    final scid = (Random().nextInt(0x7ffffffe) + 1)
        .toRadixString(16)
        .padLeft(8, '0');
    final server = await Process.start(adbPath, serverArguments(serial, scid));
    final log = StringBuffer();
    server.stdout.listen((b) => log.write(String.fromCharCodes(b)));
    server.stderr.listen((b) => log.write(String.fromCharCodes(b)));

    final forward = await adb.run([
      '-s',
      serial,
      'forward',
      'tcp:0',
      'localabstract:scrcpy_$scid',
    ]);
    final port = int.tryParse(forward.stdout.toString().trim());
    if (port == null) {
      server.kill();
      throw McpUnsupportedOnDeviceException(
        'adb forward failed: ${forward.stderr}'.trim(),
      );
    }
    try {
      final (socket, done) = await _connect(port, server);
      final session = McpScrcpyTouchSession._(serial, server, socket, port);
      unawaited(done.then((_) => session.close()));
      return session;
    } on Object {
      server.kill();
      await adb.run(['-s', serial, 'forward', '--remove', 'tcp:$port']);
      throw McpUnsupportedOnDeviceException(
        'The scrcpy server did not accept a control connection. '
        'Server output: ${log.toString().trim()}',
      );
    }
  }

  /// adb arguments that start the control-only server. Every key must
  /// exist in the bundled jar (checked by a unit test).
  static List<String> serverArguments(String serial, String scid) => [
    '-s',
    serial,
    'shell',
    'CLASSPATH=$remoteJarPath',
    'app_process',
    '/',
    'com.genymobile.scrcpy.Server',
    ScrcpyServerConstants.version,
    'scid=$scid',
    'tunnel_forward=true',
    'video=false',
    'audio=false',
    'control=true',
    // Nothing to restore: no settings change, and the app's own session
    // keeps its jar (this one uses another path).
    'cleanup=false',
    // The agent decides when to wake the screen.
    'power_on=false',
    'clipboard_autosync=false',
    'send_device_meta=false',
  ];

  /// Connects until the server answers with its dummy byte: before it
  /// listens, adb accepts the TCP connection and closes it at once.
  static Future<(Socket, Future<void>)> _connect(
    int port,
    Process server,
  ) async {
    final deadline = DateTime.now().add(connectTimeout);
    var exited = false;
    unawaited(server.exitCode.then((_) => exited = true));
    while (!exited && DateTime.now().isBefore(deadline)) {
      final connected = await _tryConnect(port);
      if (connected != null) return connected;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    throw const SocketException('scrcpy control connection failed');
  }

  /// The socket and a future that completes when the server closes it, or
  /// `null` when the server is not listening yet.
  static Future<(Socket, Future<void>)?> _tryConnect(int port) async {
    final Socket socket;
    try {
      socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      return null;
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    final first = Completer<bool>();
    final done = Completer<void>();
    void end() {
      if (!first.isCompleted) first.complete(false);
      if (!done.isCompleted) done.complete();
    }

    // Device messages (none are requested) are drained and ignored.
    socket.listen(
      (_) {
        if (!first.isCompleted) first.complete(true);
      },
      onDone: end,
      onError: (_) => end(),
      cancelOnError: true,
    );
    final ok = await first.future.timeout(
      const Duration(seconds: 1),
      onTimeout: () => false,
    );
    if (ok) return (socket, done.future);
    await socket.close();
    socket.destroy();
    return null;
  }

  /// Closes every session, so the process can exit: an open socket, the
  /// server's adb process, and the idle timer keep Dart's event loop alive
  /// (the server did not exit after stdin closed).
  static Future<void> closeAll() =>
      Future.wait([for (final s in _sessions.values.toList()) s.close()]);

  /// Writes one or more control messages.
  void send(Uint8List message) {
    if (_closed) throw StateError('Touch session for $serial is closed.');
    _socket.add(message);
    _touch();
  }

  /// Waits until everything sent has left this process.
  Future<void> flush() => _socket.flush();

  void _touch() {
    _idle?.cancel();
    _idle = Timer(idleTimeout, close);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _idle?.cancel();
    _sessions.remove(serial);
    _socket.destroy();
    _server.kill();
    await _adb?.run(['-s', serial, 'forward', '--remove', 'tcp:$_port']);
  }
}
