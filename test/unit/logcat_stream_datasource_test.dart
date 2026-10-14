import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/logging/data/datasources/logcat_stream_datasource.dart';

class MockAdbService extends Mock implements AdbService {}
class MockProcessExecutor extends Mock implements ProcessExecutor {}
class MockProcess extends Mock implements Process {}

void main() {
  setUpAll(() {
    registerFallbackValue(ProcessSignal.sigkill);
  });

  late MockAdbService mockAdbService;
  late MockProcessExecutor mockExecutor;
  late MockProcess mockProcess;
  late LogcatStreamDatasource datasource;

  const testSerial = '192.168.43.148:5555';

  setUp(() {
    mockAdbService = MockAdbService();
    mockExecutor = MockProcessExecutor();
    mockProcess = MockProcess();

    when(() => mockAdbService.resolveAdbPath()).thenAnswer((_) async => '/usr/local/bin/adb');
    when(() => mockProcess.kill(any())).thenReturn(true);
    when(() => mockProcess.stderr).thenAnswer((_) => const Stream.empty());

    datasource = LogcatStreamDatasource(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );
  });

  tearDown(() {
    datasource.stop();
  });

  group('LogcatStreamDatasource', () {
    test('streams standard lines from process stdout', () async {
      final stdoutController = StreamController<List<int>>();
      when(() => mockProcess.stdout).thenAnswer((_) => stdoutController.stream);

      when(() => mockExecutor.start(any(), any())).thenAnswer((_) async => mockProcess);

      final stream = datasource.startLogcatStream(testSerial);
      final received = <String>[];
      final sub = stream.listen(received.add);

      stdoutController.add('Line 1\nLine 2\n'.codeUnits);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received, ['Line 1', 'Line 2']);

      await stdoutController.close();
      await sub.cancel();
    });

    test('recovers from malformed UTF-8 bytes without throwing FormatException', () async {
      final stdoutController = StreamController<List<int>>();
      when(() => mockProcess.stdout).thenAnswer((_) => stdoutController.stream);

      when(() => mockExecutor.start(any(), any())).thenAnswer((_) async => mockProcess);

      final stream = datasource.startLogcatStream(testSerial);
      final received = <String>[];
      Object? streamError;

      final sub = stream.listen(
        received.add,
        onError: (Object e) => streamError = e,
      );

      // Bytes with invalid UTF-8 sequences (0xFF, 0xFE, 0x80) followed by valid ASCII
      final rawBytes = <int>[
        0xFF, 0xFE, 0x80, // Invalid UTF-8
        0x54, 0x65, 0x73, 0x74, // 'Test'
        0x0A, // '\n'
      ];

      stdoutController.add(rawBytes);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Must not emit error
      expect(streamError, isNull);
      expect(received.length, 1);
      // Malformed bytes replaced with Unicode replacement character (\uFFFD)
      expect(received.first, contains('Test'));

      await stdoutController.close();
      await sub.cancel();
    });
  });
}
