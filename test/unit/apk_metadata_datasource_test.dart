import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_metadata_datasource.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockProcessExecutor mockExecutor;
  late ApkMetadataDatasourceImpl datasource;

  setUp(() {
    mockExecutor = MockProcessExecutor();
    datasource = ApkMetadataDatasourceImpl(processExecutor: mockExecutor);
  });

  group('ApkMetadataDatasourceImpl', () {
    test('inspectApk parses package, version, label, and SDK versions from badging', () async {
      const badgingOutput = '''
package: name='com.spotify.music' versionCode='102450' versionName='8.9.10.616' platformBuildVersionName='14' compileSdkVersion='34'
sdkVersion:'21'
targetSdkVersion:'34'
application-label:'Spotify'
application-icon-640:'res/mipmap/ic_launcher.png'
''';

      // 1. which aapt
      when(() => mockExecutor.run('/usr/bin/which', ['aapt2']))
          .thenAnswer((_) async => ProcessResult(0, 0, '/mock/aapt2', ''));
      // 2. aapt dump badging
      when(
        () => mockExecutor.run('/mock/aapt2', [
          'dump',
          'badging',
          '/test/app.apk',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 0, badgingOutput, ''));
      // 3. unzip icon
      when(
        () => mockExecutor.run('/usr/bin/unzip', [
          '-p',
          '/test/app.apk',
          'res/mipmap/ic_launcher.png',
        ], timeout: any(named: 'timeout')),
      ).thenAnswer((_) async => ProcessResult(0, 0, [1, 2, 3], ''));

      final info = await datasource.inspectApk('/test/app.apk');

      expect(info.packageName, equals('com.spotify.music'));
      expect(info.versionName, equals('8.9.10.616'));
      expect(info.versionCode, equals(102450));
      expect(info.appName, equals('Spotify'));
      expect(info.minSdkVersion, equals(21));
      expect(info.targetSdkVersion, equals(34));
      expect(info.iconBytes, equals([1, 2, 3]));
      expect(info.displayName, equals('Spotify'));
      expect(info.sdkDisplay, contains('Android 14'));
    });

    test('inspectApk falls back safely when aapt is unavailable', () async {
      when(() => mockExecutor.run(any(), any()))
          .thenAnswer((_) async => ProcessResult(0, 1, '', 'not found'));
      when(() => mockExecutor.run(any(), any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => ProcessResult(0, 1, '', 'failed'));

      final info = await datasource.inspectApk('/test/my_app.apk');

      expect(info.filePath, equals('/test/my_app.apk'));
      expect(info.fileName, equals('my_app.apk'));
      expect(info.packageName, isNull);
    });
  });
}
