import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/services/aapt_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_toolchains.dart';

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
    late Directory sdk;

    setUp(() {
      executor = MockProcessExecutor();
      sdk = Directory.systemTemp.createTempSync('aapt_sdk_');
      when(() => executor.run(any(), any()))
          .thenAnswer((_) async => ProcessResult(0, 1, '', ''));
    });

    tearDown(() => sdk.deleteSync(recursive: true));

    // ANDROID_HOME points at a real temp folder so the SDK scan runs on disk.
    AaptPathResolver buildResolver(HostOs os) => AaptPathResolver(
      processExecutor: executor,
      toolchain: toolchainFor(os, {
        'HOME': '/home/dev',
        'ANDROID_HOME': sdk.path,
      }),
    );

    File createTool(String version, String bin) =>
        File(p.join(sdk.path, 'build-tools', version, bin))
          ..createSync(recursive: true);

    test('picks the newest build-tools version from the SDK', () async {
      createTool('9.0.0', 'aapt');
      final newest = createTool('34.0.0', 'aapt2');

      expect(await buildResolver(HostOs.macos).resolve(), newest.path);
    });

    test('queries `where` for aapt2.exe with a Windows toolchain', () async {
      when(() => executor.run('where', ['aapt2.exe'])).thenAnswer(
        (_) async => ProcessResult(0, 0, 'C:\\sdk\\aapt2.exe\r\n', ''),
      );

      expect(
        await buildResolver(HostOs.windows).resolve(),
        r'C:\sdk\aapt2.exe',
      );
    });

    test('returns the first PATH match and caches it', () async {
      when(() => executor.run('/usr/bin/which', ['aapt2']))
          .thenAnswer((_) async => ProcessResult(0, 0, '/bin/aapt2\n', ''));
      final resolver = buildResolver(HostOs.macos);

      expect(await resolver.resolve(), '/bin/aapt2');
      expect(await resolver.resolve(), '/bin/aapt2');
      verify(() => executor.run('/usr/bin/which', ['aapt2'])).called(1);
    });

    test('returns null when aapt is not installed', () async {
      expect(await buildResolver(HostOs.macos).resolve(), isNull);
    });
  });
}
