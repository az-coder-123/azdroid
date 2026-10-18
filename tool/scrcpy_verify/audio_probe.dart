import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Opens the scrcpy audio socket (between video and control) and checks the
/// stream the app plays: a raw PCM header, then packets
/// (docs/native-audio-contract.md).
class AudioProbe {
  AudioProbe({required this.port, required this.adb, required this.serial});

  final int port;
  final String adb;
  final String serial;

  static const int _rawCodecId = 0x00726177;
  static const int _disabledCode = 0;
  static const int _firstAudioSdk = 30; // Android 11.

  Socket? _socket;
  final BytesBuilder _header = BytesBuilder();
  int? codecId;
  int bytesAfterHeader = 0;

  /// Connects; the server must have accepted the video socket already.
  Future<void> connect() async {
    _socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    _socket!.listen((chunk) {
      var data = chunk;
      if (codecId == null) {
        final need = 4 - _header.length;
        _header.add(data.take(need).toList());
        data = data.length > need ? data.sublist(need) : Uint8List(0);
        if (_header.length == 4) {
          codecId = ByteData.sublistView(_header.toBytes()).getUint32(0);
        }
      }
      bytesAfterHeader += data.length;
    }, onError: (Object _) {});
  }

  Future<void> close() async => _socket?.destroy();

  /// Raw PCM on Android 11+, "disabled" on older devices.
  Future<bool> isOk() async =>
      codecId == await _expectedCodec() &&
      (codecId != _rawCodecId || bytesAfterHeader > 0);

  Future<String> describe() async {
    final sdk = await _sdk();
    final kind = switch (codecId) {
      null => 'no header',
      _rawCodecId => 'raw PCM',
      _disabledCode => 'disabled',
      final other => 'codec 0x${other.toRadixString(16)}',
    };
    return 'audio: $kind (Android SDK $sdk), '
        '$bytesAfterHeader bytes after the header';
  }

  Future<int> _expectedCodec() async =>
      await _sdk() >= _firstAudioSdk ? _rawCodecId : _disabledCode;

  Future<int> _sdk() async {
    final r = await Process.run(adb, [
      '-s',
      serial,
      'shell',
      'getprop',
      'ro.build.version.sdk',
    ]);
    return int.tryParse('${r.stdout}'.trim()) ?? 0;
  }
}
