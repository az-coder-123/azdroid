import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ServerSocket server;
  late SocketScrcpyControlChannel channel;

  setUp(() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    channel = SocketScrcpyControlChannel();
  });

  tearDown(() async {
    await channel.close();
    await server.close();
  });

  test('sends bytes to the forwarded port and reports the device', () async {
    final received = Completer<List<int>>();
    server.listen((client) => client.listen(received.complete));

    expect(
      await channel.connect(deviceSerial: 'dev:5555', port: server.port),
      isTrue,
    );
    expect(channel.isConnected, isTrue);
    expect(channel.deviceSerial, 'dev:5555');
    expect(channel.send(Uint8List.fromList([4, 1])), isTrue);

    expect(await received.future, [4, 1]);
  });

  test('marks itself closed when the server closes the socket', () async {
    server.listen((client) => client.destroy());
    await channel.connect(deviceSerial: 'dev:5555', port: server.port);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(channel.isConnected, isFalse);
    expect(channel.send(Uint8List.fromList([4, 1])), isFalse);
  });

  test('returns false when nothing listens on the port', () async {
    final port = server.port;
    await server.close();

    expect(
      await channel.connect(deviceSerial: 'dev:5555', port: port),
      isFalse,
    );
    expect(channel.isConnected, isFalse);
  });
}
