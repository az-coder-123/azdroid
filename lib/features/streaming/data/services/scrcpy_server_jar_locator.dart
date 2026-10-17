import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:flutter/services.dart';

/// Finds the bundled `scrcpy-server.jar` on disk for `adb push`.
///
/// Order: project folder (`flutter run`), the release bundle location from
/// [HostPaths.flutterAssetPath], then extraction from the asset bundle into
/// the temp folder.
class ScrcpyServerJarLocator {
  ScrcpyServerJarLocator({
    HostPaths? hostPaths,
    AssetBundle? bundle,
    this.devCheckoutPath = assetKey,
  }) : _paths = hostPaths ?? SystemHostPaths(),
       _bundle = bundle ?? rootBundle;

  /// Flutter asset key of the bundled scrcpy server.
  static const String assetKey = 'assets/scrcpy-server.jar';

  /// File name used when the jar is extracted to the temp folder.
  static const String extractedFileName = 'scrcpy-server.jar';

  /// Jar location relative to the working directory during `flutter run`.
  final String devCheckoutPath;

  final HostPaths _paths;
  final AssetBundle _bundle;

  /// Absolute path of a readable jar, or `null` when it cannot be found.
  Future<String?> locate() async {
    final direct = File(devCheckoutPath);
    if (await direct.exists()) return direct.path;

    final bundled = File(_paths.flutterAssetPath(assetKey));
    if (await bundled.exists()) return bundled.path;

    return _extractFromBundle();
  }

  Future<String?> _extractFromBundle() async {
    try {
      final data = await _bundle.load(assetKey);
      final target = File(
        _paths.context.join(_paths.tempDirectory, extractedFileName),
      );
      await target.writeAsBytes(data.buffer.asUint8List());
      return target.path;
    } on Object catch (error) {
      // rootBundle reports a missing asset with FlutterError (an Error).
      AppLogger.warning('Failed to extract scrcpy-server.jar', error: error);
      return null;
    }
  }
}
