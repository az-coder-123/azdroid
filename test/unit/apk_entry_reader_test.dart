import 'dart:io';

import 'package:archive/archive.dart';
import 'package:desk_droid/features/apk_installer/data/services/apk_entry_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late String apkPath;
  const reader = ZipApkEntryReader();

  setUp(() {
    dir = Directory.systemTemp.createTempSync('apk_reader_');
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('res/mipmap/ic_launcher.png', [7, 8, 9]))
      ..addFile(ArchiveFile.string('AndroidManifest.xml', '<manifest/>'));
    apkPath = p.join(dir.path, 'app.apk');
    File(apkPath).writeAsBytesSync(ZipEncoder().encode(archive));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('reads the requested entry bytes', () async {
    expect(await reader.readEntry(apkPath, 'res/mipmap/ic_launcher.png'), [
      7,
      8,
      9,
    ]);
  });

  test('returns null for a missing entry', () async {
    expect(await reader.readEntry(apkPath, 'res/missing.png'), isNull);
  });

  test('returns null for a file that is not a zip', () async {
    final bogus = File(p.join(dir.path, 'bogus.apk'))
      ..writeAsStringSync('not a zip');
    expect(await reader.readEntry(bogus.path, 'any'), isNull);
  });
}
