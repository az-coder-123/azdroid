import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/datasources/clipboard_datasource.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

class MockAdbService extends Mock implements AdbService {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MockAdbService mockAdbService;
  late ClipboardDatasourceImpl datasource;

  const testSerial = '192.168.1.100:5555';
  const adbPath = '/usr/local/bin/adb';

  setUp(() {
    mockExecutor = MockProcessExecutor();
    mockAdbService = MockAdbService();
    datasource = ClipboardDatasourceImpl(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );

    when(() => mockAdbService.resolveAdbPath())
        .thenAnswer((_) async => adbPath);
  });

  group('ClipboardDatasourceImpl - readDeviceClipboard', () {
    test(
      'returns text directly from cmd clipboard get when supported',
      () async {
        when(
          () => mockExecutor.run(adbPath, [
            '-s',
            testSerial,
            'shell',
            'cmd',
            'clipboard',
            'get',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer(
          (_) async => ProcessResult(1234, 0, 'Hello Android Clipboard', ''),
        );

        final text = await datasource.readDeviceClipboard(testSerial);
        expect(text, 'Hello Android Clipboard');
      },
    );

    test(
      'falls back to clipper.get when cmd clipboard is not implemented',
      () async {
        when(
          () => mockExecutor.run(adbPath, [
            '-s',
            testSerial,
            'shell',
            'cmd',
            'clipboard',
            'get',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer(
          (_) async =>
              ProcessResult(1234, 0, 'No shell command implementation.', ''),
        );

        when(
          () => mockExecutor.run(adbPath, [
            '-s',
            testSerial,
            'shell',
            'am',
            'broadcast',
            '-a',
            'clipper.get',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer(
          (_) async => ProcessResult(
            1235,
            0,
            'Broadcasting: Intent { act=clipper.get }\nBroadcast completed: result=0, data="Clipper text"',
            '',
          ),
        );

        final text = await datasource.readDeviceClipboard(testSerial);
        expect(text, 'Clipper text');
      },
    );

    test('returns null when both methods fail', () async {
      when(
        () => mockExecutor.run(adbPath, [
          '-s',
          testSerial,
          'shell',
          'cmd',
          'clipboard',
          'get',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1234, 1, '', 'Error'));

      when(
        () => mockExecutor.run(adbPath, [
          '-s',
          testSerial,
          'shell',
          'am',
          'broadcast',
          '-a',
          'clipper.get',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1235, 1, '', 'No receiver'));

      final text = await datasource.readDeviceClipboard(testSerial);
      expect(text, isNull);
    });
  });

  group('ClipboardDatasourceImpl - writeDeviceClipboard', () {
    test('returns true when cmd clipboard set succeeds', () async {
      when(
        () => mockExecutor.run(adbPath, [
          '-s',
          testSerial,
          'shell',
          'cmd',
          'clipboard',
          'set',
          'Hello World',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1234, 0, '', ''));

      final success = await datasource.writeDeviceClipboard(
        testSerial,
        'Hello World',
      );
      expect(success, isTrue);
    });

    test('falls back to clipper.set when cmd clipboard returns No shell command implementation', () async {
      when(
        () => mockExecutor.run(adbPath, [
          '-s',
          testSerial,
          'shell',
          'cmd',
          'clipboard',
          'set',
          'Fallback Text',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async =>
            ProcessResult(1234, 0, 'No shell command implementation.', ''),
      );

      when(
        () => mockExecutor.run(adbPath, [
          '-s',
          testSerial,
          'shell',
          'am',
          'broadcast',
          '-a',
          'clipper.set',
          '--es',
          'text',
          'Fallback Text',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) async =>
            ProcessResult(1235, 0, 'Broadcast completed: result=0', ''),
      );

      final success = await datasource.writeDeviceClipboard(
        testSerial,
        'Fallback Text',
      );
      expect(success, isTrue);
    });
  });
}
