// Downloads the pinned Android Platform-Tools (adb) into vendor/ so builds
// can bundle it. Run from the project root:
//
//   dart run tool/fetch_platform_tools.dart            # current host OS
//   dart run tool/fetch_platform_tools.dart --os=windows
//   dart run tool/fetch_platform_tools.dart --os=all
//
// See docs/bundled-platform-tools.md.
import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/core/platform/host_os.dart';

import 'platform_tools/platform_tools_installer.dart';
import 'platform_tools/platform_tools_manifest.dart';

Future<void> main(List<String> args) async {
  final targets = _parseTargets(args);
  final installer = PlatformToolsInstaller(download: _download);
  try {
    for (final os in targets) {
      final package = platformToolsPackages[os];
      if (package == null) {
        stderr.writeln('No platform-tools package configured for ${os.name}');
        exitCode = 64;
        return;
      }
      await installer.install(package, vendorDirectory(os));
    }
  } on PlatformToolsException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on IOException catch (error) {
    stderr.writeln('Download failed: $error');
    exitCode = 1;
  }
}

List<HostOs> _parseTargets(List<String> args) {
  const prefix = '--os=';
  final value = args
      .firstWhere((a) => a.startsWith(prefix), orElse: () => '')
      .replaceFirst(prefix, '');
  if (value.isEmpty) return [HostOs.current];
  if (value == 'all') return platformToolsPackages.keys.toList();
  return [HostOs.values.byName(value)];
}

Future<Uint8List> _download(Uri url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return builder.takeBytes();
  } finally {
    client.close();
  }
}
