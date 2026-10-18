import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_channel.dart';

/// Records every message instead of writing to a socket.
class FakeControlChannel implements ScrcpyControlChannel {
  FakeControlChannel({this.connectedSerial});

  String? connectedSerial;
  final List<Uint8List> sent = [];

  @override
  String? get deviceSerial => connectedSerial;

  @override
  bool get isConnected => connectedSerial != null;

  @override
  Future<bool> connect({
    required String deviceSerial,
    required int port,
  }) async {
    connectedSerial = deviceSerial;
    return true;
  }

  @override
  bool send(Uint8List message) {
    if (!isConnected) return false;
    sent.add(message);
    return true;
  }

  @override
  Future<void> close() async => connectedSerial = null;
}
