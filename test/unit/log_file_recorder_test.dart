import 'dart:io';

import 'package:desk_droid/features/logging/data/datasources/log_file_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogFileRecorder recorder;
  late Directory tempDir;

  setUp(() {
    recorder = LogFileRecorder();
    tempDir = Directory.systemTemp.createTempSync('log_recorder_test_');
  });

  tearDown(() async {
    await recorder.stopRecording();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LogFileRecorder', () {
    test('starts and records lines to local disk asynchronously', () async {
      final targetFile = '${tempDir.path}/test_session.log';

      final path = await recorder.startRecording(targetFile);
      expect(path, targetFile);
      expect(recorder.status.isRecording, isTrue);

      recorder.writeLine('Line 1: System initialized');
      recorder.writeLine('Line 2: Camera hal bound');

      final finalStatus = await recorder.stopRecording();
      expect(finalStatus.isRecording, isFalse);
      expect(finalStatus.linesWritten, 2);
      expect(finalStatus.bytesWritten, greaterThan(0));

      final file = File(targetFile);
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('Line 1: System initialized'));
      expect(content, contains('Line 2: Camera hal bound'));
      expect(content, contains('DeskDroid Real-time Logcat Session Started'));
      expect(content, contains('DeskDroid Logcat Session Ended'));
    });

    test(
      'generates valid default log file path containing serial and timestamp',
      () {
        final path = recorder.generateDefaultLogFilePath('192.168.43.148:5555');
        expect(path, contains('192_168_43_148_5555'));
        expect(path, endsWith('.log'));
      },
    );

    test('formattedSize formats bytes, KB, and MB accurately', () {
      expect(
        recorder.status.copyWith(bytesWritten: 500).formattedSize,
        '500 B',
      );
      expect(
        recorder.status.copyWith(bytesWritten: 1536).formattedSize,
        '1.5 KB',
      );
      expect(
        recorder.status.copyWith(bytesWritten: 2097152).formattedSize,
        '2.00 MB',
      );
    });
  });
}
