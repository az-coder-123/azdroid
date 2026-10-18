import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// scrcpy-server refuses to start when the version argument sent by the
/// client differs from its own build ("The server version (X) does not match
/// the client (Y)"). This guard keeps the bundled jar, the client constant,
/// and the README badge on the same version.
void main() {
  // `flutter test` always runs with the package root as working directory.
  final jarFile = File(ScrcpyServerConstants.assetKey);
  final mismatchMessage = RegExp(
    r'The server version \(([0-9.]+)\) does not match',
  );

  String bundledServerVersion() {
    final archive = ZipDecoder().decodeBytes(jarFile.readAsBytesSync());
    final dex = archive.findFile('classes.dex')?.readBytes();
    expect(dex, isNotNull, reason: 'scrcpy-server.jar has no classes.dex');
    final match = mismatchMessage.firstMatch(latin1.decode(dex!));
    expect(match, isNotNull, reason: 'version string not found in classes.dex');
    return match!.group(1)!;
  }

  test('client version matches the bundled scrcpy-server.jar', () {
    expect(ScrcpyServerConstants.version, bundledServerVersion());
  });

  test('README badge shows the bundled scrcpy version', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('badge/scrcpy-v${ScrcpyServerConstants.version}-'));
  });
}
