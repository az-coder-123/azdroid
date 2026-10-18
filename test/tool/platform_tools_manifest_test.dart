import 'package:desk_droid/core/platform/host_os.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/platform_tools/platform_tools_manifest.dart';

void main() {
  test('every supported desktop OS has a pinned package', () {
    expect(
      platformToolsPackages.keys,
      containsAll([HostOs.macos, HostOs.windows]),
    );
  });

  for (final MapEntry(key: os, value: package)
      in platformToolsPackages.entries) {
    group('${os.name} package', () {
      test('archive name matches the pinned version', () {
        expect(package.archiveName, contains('_r$platformToolsVersion-'));
      });

      test('ships adb, its license notice, and the version file', () {
        expect(package.files.values, contains(os.executableName('adb')));
        expect(package.files.values, contains(noticeFileName));
        expect(package.files.values, contains(sourcePropertiesFileName));
      });

      test('checksums are well-formed hex digests', () {
        expect(package.sha1, matches(RegExp(r'^[0-9a-f]{40}$')));
        expect(package.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      });

      test('executables are a subset of the shipped files', () {
        expect(
          package.files.values.toSet().containsAll(package.executables),
          isTrue,
        );
      });
    });
  }
}
