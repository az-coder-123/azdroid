import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

class MockAdbService extends Mock implements AdbService {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MockAdbService mockAdbService;
  late ControlDatasourceImpl datasource;

  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockExecutor = MockProcessExecutor();
    mockAdbService = MockAdbService();
    datasource = ControlDatasourceImpl(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );

    when(() => mockAdbService.resolveAdbPath())
        .thenAnswer((_) async => '/opt/homebrew/bin/adb');
  });

  group('ControlDatasourceImpl', () {
    test('injectTap executes adb shell input tap', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'input',
          'tap',
          '540',
          '1200',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final result = await datasource.injectTap(testSerial, 540, 1200);

      expect(result, isTrue);
      verify(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'input',
          'tap',
          '540',
          '1200',
        ], timeout: any(named: 'timeout')),
      ).called(1);
    });

    test('injectSwipe executes adb shell input swipe', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'input',
          'swipe',
          '100',
          '200',
          '300',
          '400',
          '150',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final result = await datasource.injectSwipe(
        testSerial,
        100,
        200,
        300,
        400,
        150,
      );

      expect(result, isTrue);
    });

    test('injectKeyevent executes adb shell input keyevent', () async {
      when(
        () => mockExecutor.run('/opt/homebrew/bin/adb', [
          '-s',
          testSerial,
          'shell',
          'input',
          'keyevent',
          '4',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      final result = await datasource.injectKeyevent(testSerial, 4);

      expect(result, isTrue);
    });

    test(
      'injectText sanitizes spaces with %s and escapes shell characters',
      () async {
        when(
          () => mockExecutor.run('/opt/homebrew/bin/adb', [
            '-s',
            testSerial,
            'shell',
            'input',
            'text',
            r'Hello%sWorld\$123',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

        final result = await datasource.injectText(
          testSerial,
          'Hello World\$123',
        );

        expect(result, isTrue);
      },
    );
  });
}
