import 'dart:io';

import 'package:desk_droid/core/constants/apk_installer_constants.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/services/aapt_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  group('AaptPathResolver.compareVersionNames', () {
    test('orders numeric segments numerically, not lexically', () {
      expect(AaptPathResolver.compareVersionNames('34.0.0', '9.0.0'), 1);
      expect(AaptPathResolver.compareVersionNames('30.0.3', '30.0.10'), -1);
      expect(AaptPathResolver.compareVersionNames('33.0.1', '33.0.1'), 0);
    });

    test('treats missing segments as zero', () {
      expect(AaptPathResolver.compareVersionNames('34', '34.0.0'), 0);
    });
  });

  group('AaptPathResolver.resolve', () {
    late MockProcessExecutor executor;
    late Directory home;

    setUp(() {
      executor = MockProcessExecutor();
      home = Directory.systemTemp.createTempSync('aapt_home_');
      when(() => executor.run(ApkInstallerConstants.whichPath, any()))
          .thenAnswer((_) async => ProcessResult(0, 1, '', ''));
    });

    tearDown(() => home.deleteSync(recursive: true));

    File createTool(String version, String bin) {
      final file = File(
        '${home.path}/${ApkInstallerConstants.androidSdkBuildToolsSubpath}'
        '/$version/$bin',
      )..createSync(recursive: true);
      return file;
    }

    test('picks the newest build-tools version from the SDK', () async {
      createTool('9.0.0', 'aapt');
      final newest = createTool('34.0.0', 'aapt2');

      final resolver = AaptPathResolver(
        processExecutor: executor,
        environment: {'HOME': home.path},
      );

      expect(await resolver.resolve(), newest.path);
    });

    test('returns PATH result first and caches it', () async {
      when(() => executor.run(ApkInstallerConstants.whichPath, ['aapt2']))
          .thenAnswer((_) async => ProcessResult(0, 0, '/bin/aapt2\n', ''));

      final resolver = AaptPathResolver(
        processExecutor: executor,
        environment: {'HOME': home.path},
      );

      expect(await resolver.resolve(), '/bin/aapt2');
      expect(await resolver.resolve(), '/bin/aapt2');
      verify(() => executor.run(ApkInstallerConstants.whichPath, ['aapt2']))
          .called(1);
    });

    test('returns null when aapt is not installed', () async {
      final resolver = AaptPathResolver(
        processExecutor: executor,
        environment: {'HOME': home.path},
      );

      expect(await resolver.resolve(), isNull);
    });
  });
}
