import 'package:desk_droid/features/streaming/data/services/scrcpy_server_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScrcpyServerOutput.classify', () {
    test('detects readiness from the device line', () {
      expect(
        ScrcpyServerOutput.classify(
          '[server] INFO: Device: [Xiaomi] Redmi M2004J19C (Android 10)',
        ),
        ScrcpyServerEvent.ready,
      );
    });

    test('detects a version mismatch before anything else', () {
      expect(
        ScrcpyServerOutput.classify(
          '[server] ERROR: The server version (2.1) does not match the client '
          '(5.0.1)',
        ),
        ScrcpyServerEvent.versionMismatch,
      );
    });

    test('flags server errors such as missing Android APIs', () {
      expect(
        ScrcpyServerOutput.classify(
          '[server] ERROR: Exception on thread Thread[video,5,main]',
        ),
        ScrcpyServerEvent.error,
      );
    });

    test('treats other output as diagnostics', () {
      expect(
        ScrcpyServerOutput.classify('[server] INFO: Using encoder c2.mtk.avc'),
        ScrcpyServerEvent.other,
      );
    });
  });

  test('parseChunk splits CRLF chunks and drops blank lines', () {
    final events = ScrcpyServerOutput.parseChunk(
      '[server] INFO: Device: [Google] Pixel 8 (Android 16)\r\n'
      '\r\n'
      'java.lang.AssertionError\r\n',
    );

    expect(events.map((e) => e.$1), [
      ScrcpyServerEvent.ready,
      ScrcpyServerEvent.other,
    ]);
    expect(events.first.$2, startsWith('[server] INFO: Device'));
  });
}
