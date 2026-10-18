import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'platform_tools_manifest.dart';

/// Raised when a download or archive does not match the pinned manifest.
class PlatformToolsException implements Exception {
  const PlatformToolsException(this.message);
  final String message;

  @override
  String toString() => 'PlatformToolsException: $message';
}

/// Verifies, extracts, and stamps a platform-tools archive.
///
/// Network access is injected through [download], so everything except the
/// HTTP request is testable offline.
class PlatformToolsInstaller {
  PlatformToolsInstaller({required this.download, this.log = print});

  /// Returns the raw bytes at [url].
  final Future<Uint8List> Function(Uri url) download;
  final void Function(String message) log;

  /// Whether [outputDir] already holds [platformToolsVersion] with every file.
  bool isInstalled(PlatformToolsPackage package, String outputDir) {
    final stamp = File(p.join(outputDir, stampFileName));
    if (!stamp.existsSync() ||
        stamp.readAsStringSync().trim() != platformToolsVersion) {
      return false;
    }
    return package.files.values.every(
      (name) => File(p.join(outputDir, name)).existsSync(),
    );
  }

  /// Downloads (unless already installed) and extracts [package].
  Future<void> install(PlatformToolsPackage package, String outputDir) async {
    if (isInstalled(package, outputDir)) {
      log('platform-tools $platformToolsVersion already in $outputDir');
      return;
    }
    log('Downloading ${package.url}');
    final bytes = await download(Uri.parse(package.url));
    verify(package, bytes);
    extract(package, bytes, outputDir);
    File(p.join(outputDir, stampFileName))
        .writeAsStringSync('$platformToolsVersion\n');
    log('Installed platform-tools $platformToolsVersion into $outputDir');
  }

  /// Throws unless [bytes] has the pinned size and SHA-256.
  void verify(PlatformToolsPackage package, List<int> bytes) {
    if (bytes.length != package.sizeBytes) {
      throw PlatformToolsException(
        '${package.archiveName}: expected ${package.sizeBytes} bytes, '
        'got ${bytes.length}',
      );
    }
    final actual = sha256.convert(bytes).toString();
    if (actual != package.sha256) {
      throw PlatformToolsException(
        '${package.archiveName}: SHA-256 mismatch '
        '(expected ${package.sha256}, got $actual)',
      );
    }
  }

  /// Writes only the files listed in the manifest into [outputDir].
  void extract(
    PlatformToolsPackage package,
    List<int> bytes,
    String outputDir,
  ) {
    final archive = ZipDecoder().decodeBytes(bytes);
    Directory(outputDir).createSync(recursive: true);
    for (final MapEntry(key: entryPath, value: outputName)
        in package.files.entries) {
      final entry = archive.findFile(entryPath);
      final content = entry?.readBytes();
      if (content == null) {
        throw PlatformToolsException('Missing $entryPath in archive');
      }
      final target = File(p.join(outputDir, outputName))
        ..writeAsBytesSync(content, flush: true);
      if (package.executables.contains(outputName) && !Platform.isWindows) {
        _makeExecutable(target.path);
      }
    }
  }

  void _makeExecutable(String path) {
    final result = Process.runSync('chmod', ['755', path]);
    if (result.exitCode != 0) {
      throw PlatformToolsException('chmod failed for $path: ${result.stderr}');
    }
  }
}
