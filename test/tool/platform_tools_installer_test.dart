import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/platform_tools/platform_tools_installer.dart';
import '../../tool/platform_tools/platform_tools_manifest.dart';

void main() {
  late Directory out;
  late Uint8List zipBytes;
  late PlatformToolsPackage package;
  late int downloads;

  setUp(() {
    out = Directory.systemTemp.createTempSync('ptools_');
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('platform-tools/adb', [1, 2, 3]))
      ..addFile(ArchiveFile.string('platform-tools/NOTICE.txt', 'Apache'))
      ..addFile(ArchiveFile.bytes('platform-tools/fastboot', [9]));
    zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    package = PlatformToolsPackage(
      archiveName: 'fake.zip',
      sizeBytes: zipBytes.length,
      sha1: 'unused',
      sha256: sha256.convert(zipBytes).toString(),
      files: const {
        'platform-tools/adb': 'adb',
        'platform-tools/NOTICE.txt': noticeFileName,
      },
      executables: const {'adb'},
    );
    downloads = 0;
  });

  tearDown(() => out.deleteSync(recursive: true));

  PlatformToolsInstaller installer({Uint8List? bytes}) =>
      PlatformToolsInstaller(
        download: (_) async {
          downloads++;
          return bytes ?? zipBytes;
        },
        log: (_) {},
      );

  test('extracts only the manifest files and stamps the version', () async {
    await installer().install(package, out.path);

    expect(File(p.join(out.path, 'adb')).readAsBytesSync(), [1, 2, 3]);
    expect(File(p.join(out.path, noticeFileName)).existsSync(), isTrue);
    expect(File(p.join(out.path, 'fastboot')).existsSync(), isFalse);
    expect(
      File(p.join(out.path, stampFileName)).readAsStringSync().trim(),
      platformToolsVersion,
    );
  });

  test('marks executables as runnable on POSIX hosts', () async {
    await installer().install(package, out.path);
    if (!Platform.isWindows) {
      final mode = File(p.join(out.path, 'adb')).statSync().mode;
      expect(mode & 0x49, 0x49); // u+x, g+x, o+x
    }
  });

  test('skips the download when the version is already installed', () async {
    final tool = installer();
    await tool.install(package, out.path);
    await tool.install(package, out.path);

    expect(downloads, 1);
  });

  test('rejects an archive with a different SHA-256', () async {
    final tampered = Uint8List.fromList(zipBytes)..[0] ^= 0xFF;

    await expectLater(
      installer(bytes: tampered).install(package, out.path),
      throwsA(isA<PlatformToolsException>()),
    );
    expect(File(p.join(out.path, 'adb')).existsSync(), isFalse);
  });

  test('rejects an archive with a different size', () async {
    final truncated = Uint8List.sublistView(zipBytes, 0, zipBytes.length - 1);

    await expectLater(
      installer(bytes: truncated).install(package, out.path),
      throwsA(isA<PlatformToolsException>()),
    );
  });
}
