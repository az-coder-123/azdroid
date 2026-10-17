import 'dart:io';

import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/services/remote_media_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor executor;
  late RemoteMediaScanner scanner;

  setUp(() {
    executor = MockProcessExecutor();
    scanner = RemoteMediaScanner(processExecutor: executor);
    when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));
  });

  test('isMedia matches extensions case-insensitively', () {
    expect(RemoteMediaScanner.isMedia('/a/Photo.JPG'), isTrue);
    expect(RemoteMediaScanner.isMedia(r'C:\clips\video.mp4'), isTrue);
    expect(RemoteMediaScanner.isMedia('/a/notes.txt'), isFalse);
  });

  test('broadcasts a scan for the pushed file with an Android path', () async {
    await scanner.scanPushedFile(
      adb: 'adb',
      serial: 'S1',
      remoteDirectory: '/sdcard/Download',
      localPath: '/Users/dev/Pictures/cat.png',
    );

    final args =
        verify(
              () => executor.run(
                'adb',
                captureAny(),
                timeout: any(named: 'timeout'),
              ),
            ).captured.single
            as List<String>;
    expect(args.last, 'file:///sdcard/Download/cat.png');
  });

  test('skips non-media files', () async {
    await scanner.scanPushedFile(
      adb: 'adb',
      serial: 'S1',
      remoteDirectory: '/sdcard/Download/',
      localPath: '/Users/dev/report.pdf',
    );

    verifyNever(
      () => executor.run(any(), any(), timeout: any(named: 'timeout')),
    );
  });

  test('swallows process failures after logging', () async {
    when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
        .thenThrow(const ProcessException('adb', [], 'offline'));

    await expectLater(
      scanner.scanPushedFile(
        adb: 'adb',
        serial: 'S1',
        remoteDirectory: '/sdcard/DCIM',
        localPath: '/x/clip.mp4',
      ),
      completes,
    );
  });
}
