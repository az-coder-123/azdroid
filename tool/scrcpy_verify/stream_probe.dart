import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Connects to a forwarded scrcpy video socket and checks the stream format
/// used by v4.0+: a 69-byte header (dummy byte, name, codec), then 12-byte
/// packet headers. A session packet (bit 63) carries the video size and comes
/// first; media packets flag config (bit 62) and key frames (bit 61) and carry
/// H.264 Annex B payloads (docs/native-video-contract.md).
class StreamProbe {
  StreamProbe({required this.port});

  final int port;

  static const int _headerSize = 69;
  static const int _packetHeaderSize = 12;
  static const int _connectAttempts = 30;
  static const Duration _retryDelay = Duration(milliseconds: 300);
  static const Duration _readTimeout = Duration(seconds: 15);

  /// A static screen yields only a few packets (Redmi 9: 12) and then
  /// none, so once the stream is healthy, a pause this long ends the check.
  static const Duration _idleAfterHealthy = Duration(seconds: 2);
  static const Duration _pollInterval = Duration(milliseconds: 50);

  _SocketReader? _activeReader;

  /// Reads the stream like Azdroid does: the dummy byte first, then
  /// [onVideoAccepted] (which must open the control socket, because the
  /// server sends the rest of the header only after that), then the header
  /// and packets until the stream is healthy and either [packets] arrived
  /// or packets pause.
  ///
  /// Packets keep being read in the background until [close]: all
  /// `adb forward` sockets share one adb connection, so an unread video
  /// socket would stall control messages too.
  Future<StreamReport> run({
    required int packets,
    required Future<void> Function() onVideoAccepted,
  }) async {
    for (var attempt = 1; attempt <= _connectAttempts; attempt++) {
      final reader = await _SocketReader.connect(port);
      try {
        // Same retry policy as the native plugins: the forward accepts the
        // connection even before the device socket listens.
        final dummy = await reader.read(1, timeout: _readTimeout);
        await onVideoAccepted();
        final header = Uint8List.fromList([
          ...dummy,
          ...await reader.read(_headerSize - 1, timeout: _readTimeout),
        ]);
        final report = StreamReport(attempt: attempt, header: header);
        _activeReader = reader;
        unawaited(_readPackets(reader, report));
        await _waitUntilChecked(report, packets);
        return report;
      } on TimeoutException {
        await reader.close();
        rethrow;
      } on StateError {
        if (!identical(_activeReader, reader)) {
          await reader.close();
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        rethrow;
      }
    }
    throw StateError('No stream header after $_connectAttempts attempts');
  }

  Future<void> _waitUntilChecked(StreamReport report, int packets) async {
    final stopwatch = Stopwatch()..start();
    while (report.totalPackets < packets) {
      final idle = report.sinceLastPacket;
      if (report.isHealthy && idle != null && idle > _idleAfterHealthy) {
        return;
      }
      if (stopwatch.elapsed > _readTimeout) {
        throw TimeoutException('Stream not healthy', _readTimeout);
      }
      await Future<void>.delayed(_pollInterval);
    }
  }

  /// Parses packets until the socket closes or [close] is called.
  Future<void> _readPackets(_SocketReader reader, StreamReport report) async {
    try {
      while (true) {
        final meta = ByteData.sublistView(await reader.read(_packetHeaderSize));
        final flags = meta.getUint64(0);
        if ((flags >> 63) & 1 == 1) {
          report.addSession(meta.getUint32(4), meta.getUint32(8));
          continue;
        }
        final payload = await reader.read(meta.getUint32(8));
        report.addPacket(
          isConfig: (flags >> 62) & 1 == 1,
          isKeyFrame: (flags >> 61) & 1 == 1,
          payload: payload,
        );
      }
    } on Object {
      // Closed by close() or by the device; nothing left to read.
    }
  }

  /// Video bytes received so far.
  int get drainedBytes => _activeReader?.bytesRead ?? 0;

  /// Stops reading and closes the video socket.
  Future<void> close() async => _activeReader?.close();
}

/// Result of a [StreamProbe] run.
class StreamReport {
  StreamReport({required this.attempt, required Uint8List header})
    : deviceName = _text(header.sublist(1, 65)),
      codec = _text(header.sublist(65, 69));

  final int attempt;
  final String deviceName;
  final String codec;

  /// The video size from the latest session packet; 0 before the first one.
  int width = 0;
  int height = 0;

  /// Whether the session packet came before any media packet, as the
  /// official client requires.
  bool sessionFirst = false;
  int sessionPackets = 0;
  final List<String> firstPackets = [];
  int configPackets = 0;
  int keyFrames = 0;
  int totalPackets = 0;
  DateTime? _lastPacketAt;
  bool sawSpsAndPps = false;
  bool sawIdr = false;

  void addSession(int newWidth, int newHeight) {
    if (sessionPackets == 0 && totalPackets == 0) sessionFirst = true;
    sessionPackets++;
    width = newWidth;
    height = newHeight;
  }

  void addPacket({
    required bool isConfig,
    required bool isKeyFrame,
    required Uint8List payload,
  }) {
    final nals = _nalTypes(payload);
    totalPackets++;
    _lastPacketAt = DateTime.now();
    if (isConfig) configPackets++;
    if (isKeyFrame) keyFrames++;
    if (isConfig && nals.contains(7) && nals.contains(8)) sawSpsAndPps = true;
    if (isKeyFrame && nals.contains(5)) sawIdr = true;
    if (firstPackets.length < 4) {
      firstPackets.add(
        'config=$isConfig key=$isKeyFrame size=${payload.length} nal=$nals',
      );
    }
  }

  /// Time since the last packet, or `null` before the first one.
  Duration? get sinceLastPacket => switch (_lastPacketAt) {
    final at? => DateTime.now().difference(at),
    null => null,
  };

  /// A usable stream: H.264, a size from a leading session packet, SPS/PPS
  /// config, an IDR frame.
  bool get isHealthy =>
      codec == 'h264' &&
      sessionFirst &&
      width > 0 &&
      height > 0 &&
      sawSpsAndPps &&
      sawIdr;

  String describe() => [
    'connected on attempt $attempt',
    'header: name="$deviceName" codec=$codec',
    'session: size=${width}x$height packets=$sessionPackets first=$sessionFirst',
    for (final (i, p) in firstPackets.indexed) 'packet #$i: $p',
    'packets: $totalPackets (config=$configPackets, key=$keyFrames), '
        'SPS+PPS=$sawSpsAndPps, IDR=$sawIdr',
  ].join('\n');

  static String _text(List<int> bytes) =>
      latin1.decode(bytes.takeWhile((b) => b != 0).toList());

  static List<int> _nalTypes(Uint8List data) {
    final types = <int>[];
    for (var i = 0; i + 3 < data.length; i++) {
      if (data[i] == 0 && data[i + 1] == 0) {
        if (data[i + 2] == 1) {
          types.add(data[i + 3] & 0x1F);
          i += 2;
        } else if (data[i + 2] == 0 &&
            i + 4 < data.length &&
            data[i + 3] == 1) {
          types.add(data[i + 4] & 0x1F);
          i += 3;
        }
      }
    }
    return types;
  }
}

/// Owns a loopback socket and reads exact byte counts from it; throws
/// [StateError] on EOF.
class _SocketReader {
  _SocketReader._(Socket socket)
    : _socket = socket,
      _chunks = StreamIterator(socket);

  static Future<_SocketReader> connect(int port) async =>
      _SocketReader._(await Socket.connect(InternetAddress.loopbackIPv4, port));

  final Socket _socket;
  final StreamIterator<Uint8List> _chunks;
  final BytesBuilder _pending = BytesBuilder(copy: false);

  int bytesRead = 0;

  /// Reads exactly [count] bytes, waiting at most [timeout] per chunk when
  /// given. Packet reads pass none: a static screen may send nothing for a
  /// long time, which is not an error.
  Future<Uint8List> read(int count, {Duration? timeout}) async {
    while (_pending.length < count) {
      final next = _chunks.moveNext();
      if (!await (timeout == null ? next : next.timeout(timeout))) {
        throw StateError('Socket closed after ${_pending.length}/$count bytes');
      }
      bytesRead += _chunks.current.length;
      _pending.add(_chunks.current);
    }
    final all = _pending.takeBytes();
    _pending.add(all.sublist(count));
    return Uint8List.sublistView(all, 0, count);
  }

  Future<void> close() async {
    await _chunks.cancel();
    _socket.destroy();
  }
}
