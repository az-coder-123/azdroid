import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_jar_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._bytes);
  final List<int>? _bytes;

  @override
  Future<ByteData> load(String key) async {
    final bytes = _bytes;
    if (bytes == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('jar_locator_'));
  tearDown(() => root.deleteSync(recursive: true));

  SystemHostPaths pathsWithExe(String exe) => SystemHostPaths(
    os: HostOs.current,
    environment: const {},
    systemTempPath: root.path,
    executablePath: exe,
  );

  test('prefers the release bundle location when the jar exists', () async {
    final exe = p.join(root.path, 'app', 'desk_droid');
    final paths = pathsWithExe(exe);
    final bundled = File(
      paths.flutterAssetPath(ScrcpyServerJarLocator.assetKey),
    )..createSync(recursive: true);

    final locator = ScrcpyServerJarLocator(
      hostPaths: paths,
      bundle: _FakeBundle(null),
      devCheckoutPath: p.join(root.path, 'no-checkout.jar'),
    );

    expect(await locator.locate(), bundled.path);
  });

  test('extracts the asset into the temp folder as a fallback', () async {
    final locator = ScrcpyServerJarLocator(
      hostPaths: pathsWithExe(p.join(root.path, 'missing', 'exe')),
      bundle: _FakeBundle(utf8.encode('jar-bytes')),
      devCheckoutPath: p.join(root.path, 'no-checkout.jar'),
    );

    final path = await locator.locate();

    expect(path, p.join(root.path, ScrcpyServerJarLocator.extractedFileName));
    expect(File(path!).readAsStringSync(), 'jar-bytes');
  });

  test('returns null when the asset is not bundled', () async {
    final locator = ScrcpyServerJarLocator(
      hostPaths: pathsWithExe(p.join(root.path, 'missing', 'exe')),
      bundle: _FakeBundle(null),
      devCheckoutPath: p.join(root.path, 'no-checkout.jar'),
    );

    expect(await locator.locate(), isNull);
  });
}
