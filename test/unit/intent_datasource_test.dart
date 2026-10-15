import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/intent_dispatcher/data/datasources/intent_datasource.dart';
import 'package:desk_droid/features/intent_dispatcher/data/repositories/intent_repository_impl.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_request_entity.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

class MockAdbService extends Mock implements AdbService {}

void main() {
  late MockProcessExecutor mockExecutor;
  late MockAdbService mockAdbService;
  late IntentDatasourceImpl datasource;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    mockAdbService = MockAdbService();
    datasource = IntentDatasourceImpl(
      adbService: mockAdbService,
      processExecutor: mockExecutor,
    );
  });

  group('IntentDatasourceImpl', () {
    test('returns failure if ADB binary is not found', () async {
      when(() => mockAdbService.resolveAdbPath()).thenAnswer((_) async => null);

      final result = await datasource.dispatchIntent(
        'device-123',
        const IntentRequestEntity(dataUri: 'https://flutter.dev'),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('ADB binary not found'));
    });

    test(
      'builds and executes adb shell am start with URI, action, and extras',
      () async {
        when(() => mockAdbService.resolveAdbPath())
            .thenAnswer((_) async => '/mock/adb');
        when(
          () => mockExecutor.run(
            '/mock/adb',
            any(),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer(
          (_) async => ProcessResult(
            0,
            0,
            'Starting: Intent { act=android.intent.action.VIEW dat=https://flutter.dev }',
            '',
          ),
        );

        final result = await datasource.dispatchIntent(
          'device-123',
          const IntentRequestEntity(
            dataUri: 'https://flutter.dev',
            action: 'android.intent.action.VIEW',
            packageName: 'com.android.chrome',
            componentName: 'com.android.chrome/Main',
            extras: {
              'search_query': 'flutter low latency',
              'tab_count': 5,
              'is_incognito': false,
              'ratio': 3.14,
            },
          ),
        );

        expect(result.success, isTrue);
        expect(result.message, contains('Intent successfully dispatched'));

        verify(
          () => mockExecutor.run('/mock/adb', [
            '-s',
            'device-123',
            'shell',
            'am',
            'start',
            '-a',
            'android.intent.action.VIEW',
            '-d',
            'https://flutter.dev',
            '-p',
            'com.android.chrome',
            '-n',
            'com.android.chrome/Main',
            '--es',
            'search_query',
            'flutter low latency',
            '--ei',
            'tab_count',
            '5',
            '--ez',
            'is_incognito',
            'false',
            '--ef',
            'ratio',
            '3.14',
          ], timeout: any(named: 'timeout')),
        ).called(1);
      },
    );

    test('detects Activity not found in stdout and returns failure', () async {
      when(() => mockAdbService.resolveAdbPath())
          .thenAnswer((_) async => '/mock/adb');
      when(
        () => mockExecutor.run(
          '/mock/adb',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => ProcessResult(
          0,
          0,
          'Starting: Intent { act=android.intent.action.VIEW }\nError: Activity not found to handle Intent',
          '',
        ),
      );

      final result = await datasource.dispatchIntent(
        'device-123',
        const IntentRequestEntity(dataUri: 'unknown://scheme'),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Activity not found to handle Intent'));
    });

    test('detects SecurityException and returns failure', () async {
      when(() => mockAdbService.resolveAdbPath())
          .thenAnswer((_) async => '/mock/adb');
      when(
        () => mockExecutor.run(
          '/mock/adb',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => ProcessResult(
          0,
          1,
          '',
          'java.lang.SecurityException: Permission Denial',
        ),
      );

      final result = await datasource.dispatchIntent(
        'device-123',
        const IntentRequestEntity(action: 'restricted.action'),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Permission Denial'));
    });
  });

  group('IntentRepositoryImpl', () {
    test('delegates dispatchIntent directly to datasource', () async {
      when(() => mockAdbService.resolveAdbPath())
          .thenAnswer((_) async => '/mock/adb');
      when(
        () => mockExecutor.run(
          '/mock/adb',
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => ProcessResult(0, 0, 'Starting: Intent', ''));

      final repository = IntentRepositoryImpl(datasource: datasource);
      final result = await repository.dispatchIntent(
        'serial-abc',
        const IntentRequestEntity(dataUri: 'https://test.com'),
      );

      expect(result.success, isTrue);
    });
  });
}
