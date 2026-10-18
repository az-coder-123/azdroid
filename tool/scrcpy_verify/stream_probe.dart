import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Connects to a forwarded scrcpy video socket and checks the stream format
/// used by v2.0 – v3.3.x: a 77-byte header, then 12-byte packet headers
/// (bit 63 config, bit 62 key frame) with H.264 Annex B payloads.
///
/// v4.0+ adds session packets; update this probe together with the native
/// parsers when migrating (docs/native-video-contract.md).
class StreamProbe {
  StreamProbe({required this.port});

  final int port;

  static const int _headerSize = 77;
  static const int _packetHeaderSize = 12;
  static const int _connectAttempts = 30;
  static const Duration _retryDelay = Duration(milliseconds: 300);
  static const Duration _readTimeout = Duration(seconds: 15);

  _SocketReader? _activeReader;

  /// Reads the stream like DeskDroid does: the dummy byte first, then
  /// [onVideoAccepted] (which must open the control socket, because the
  /// server sends the rest of the header only after that), then the header
  /// and [packets] packets.
  ///
  /// Afterwards the video keeps being drained in the background until
  /// [close]: all `adb forward` sockets share one adb connection, so an
  /// unread video socket would stall control messages too.
  Future<StreamReport> run({
    required int packets,
    required Future<void> Function() onVideoAccepted,
  }) async {
    for (var attempt = 1; attempt <= _connectAttempts; attempt++) {
      final reader = await _SocketReader.connect(port);
      var keepOpen = false;
      try {
        // Same retry policy as the native plugins: the forward accepts the
        // connection even before the device socket listens.
        final dummy = await reader.read(1);
        await onVideoAccepted();
        final header = Uint8List.fromList([
          ...dummy,
          ...await reader.read(_headerSize - 1),
        ]);
        final report = StreamReport(attempt: attempt, header: header);
        for (var i = 0; i < packets; i++) {
          final meta = ByteData.sublistView(
            await reader.read(_packetHeaderSize),
          );
          final flags = meta.getUint64(0);
          final payload = await reader.read(meta.getUint32(8));
          report.addPacket(
            isConfig: (flags >> 63) & 1 == 1,
            isKeyFrame: (flags >> 62) & 1 == 1,
            payload: payload,
          );
        }
        keepOpen = true;
        _activeReader = reader;
        unawaited(reader.drain());
        return report;
      } on StateError {
        await Future<void>.delayed(_retryDelay);
      } finally {
        if (!keepOpen) await reader.close();
      }
    }
    throw StateError('No stream header after $_connectAttempts attempts');
  }

  /// Bytes read by the background drain so far.
  int get drainedBytes => _activeReader?.drainedBytes ?? 0;

  /// Stops draining and closes the video socket.
  Future<void> close() async => _activeReader?.close();
}

/// Result of a [StreamProbe] run.
class StreamReport {
  StreamReport({required this.attempt, required Uint8List header})
    : deviceName = _text(header.sublist(1, 65)),
      codec = _text(header.sublist(65, 69)),
      width = ByteData.sublistView(header).getUint32(69),
      height = ByteData.sublistView(header).getUint32(73);

  final int attempt;
  final String deviceName;
  final String codec;
  final int width;
  final int height;
  final List<String> firstPackets = [];
  int configPackets = 0;
  int keyFrames = 0;
  int totalPackets = 0;
  bool sawSpsAndPps = false;
  bool sawIdr = false;

  void addPacket({
    required bool isConfig,
    required bool isKeyFrame,
    required Uint8List payload,
  }) {
    final nals = _nalTypes(payload);
    totalPackets++;
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

  /// A usable stream: H.264 header with a size, SPS/PPS config, an IDR frame.
  bool get isHealthy =>
      codec == 'h264' && width > 0 && height > 0 && sawSpsAndPps && sawIdr;

  String describe() => [
    'connected on attempt $attempt',
    'header: name="$deviceName" codec=$codec size=${width}x$height',
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
  int drainedBytes = 0;

  Future<Uint8List> read(int count) async {
    while (_pending.length < count) {
      final hasMore = await _chunks.moveNext().timeout(
        StreamProbe._readTimeout,
      );
      if (!hasMore) {
        throw StateError('Socket closed after ${_pending.length}/$count bytes');
      }
      _pending.add(_chunks.current);
    }
    final all = _pending.takeBytes();
    _pending.add(all.sublist(count));
    return Uint8List.sublistView(all, 0, count);
  }

  /// Discards incoming data until the socket closes or [close] is called.
  Future<void> drain() async {
    _pending.clear();
    try {
      while (await _chunks.moveNext()) {
        drainedBytes += _chunks.current.length;
      }
    } on Object {
      // Closed by close(); nothing left to drain.
    }
  }

  Future<void> close() async {
    await _chunks.cancel();
    _socket.destroy();
  }
}
