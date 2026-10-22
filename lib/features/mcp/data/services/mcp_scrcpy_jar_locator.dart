import 'dart:io';

import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/core/platform/host_paths.dart';

/// Finds the bundled `scrcpy-server.jar` from the MCP server process, which
/// runs without Flutter's asset bundle.
///
/// Order: next to the release executable (`azdroid-mcp` sits beside the
/// app's own executable, so the app's asset path applies), the checkout of
/// a `dart run bin/azdroid_mcp.dart` started from any folder, then the
/// working directory.
class McpScrcpyJarLocator {
  McpScrcpyJarLocator({HostPaths? paths}) : _paths = paths ?? SystemHostPaths();

  final HostPaths _paths;

  static const String _assetKey = ScrcpyServerConstants.assetKey;

  String? locate() {
    final script = _paths.scriptDirectory;
    for (final candidate in [
      _paths.flutterAssetPath(_assetKey),
      if (script != null) _paths.context.join(script, '..', _assetKey),
      _assetKey,
    ]) {
      if (File(candidate).existsSync()) {
        return _paths.context.normalize(candidate);
      }
    }
    return null;
  }
}
