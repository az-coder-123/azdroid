import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_unsupported_exception.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_frame_stats.dart';

/// Measures an app's real frame rate from SurfaceFlinger (see
/// [McpFrameStats]), which covers games that `gfxinfo` cannot see.
class McpFrameRateOps {
  const McpFrameRateOps(this._adb);

  final McpAdbClient _adb;

  static const String _sectionMarker = '@@layer ';

  /// Frame stats of [package]'s busiest window.
  ///
  /// With [durationMs] > 0 the history is cleared first and the result
  /// covers only that window of time; with 0 it reads the frames already
  /// recorded (up to 128), e.g. right after a scroll.
  Future<({String layer, McpFrameStats stats})> measure(
    String serial,
    String package, {
    int durationMs = 2000,
  }) async {
    final layers = await _layersOf(serial, package);
    if (layers.isEmpty) {
      throw McpUnsupportedOnDeviceException(
        'No window of $package is on screen (dumpsys SurfaceFlinger --list); '
        'launch it and keep it in front while measuring.',
      );
    }
    if (durationMs > 0) {
      await _shell(serial, 'dumpsys SurfaceFlinger --latency-clear');
      await Future<void>.delayed(Duration(milliseconds: durationMs));
    }
    // Every candidate in one shell call; window names vary by Android
    // version, so the one with the most frames is the one drawing.
    final script = layers
        .map(
          (l) =>
              "echo '$_sectionMarker'; dumpsys SurfaceFlinger --latency "
              '${McpAdbTextOps.shellQuote(l)}',
        )
        .join('; ');
    final output = await _shell(serial, script);
    final sections = output.split(_sectionMarker).skip(1).toList();
    ({String layer, McpFrameStats stats})? best;
    for (var i = 0; i < sections.length && i < layers.length; i++) {
      final stats = McpFrameStats.parse(sections[i]);
      if (stats != null &&
          (best == null || stats.frameCount > best.stats.frameCount)) {
        best = (layer: layers[i], stats: stats);
      }
    }
    if (best == null) {
      throw const McpUnsupportedOnDeviceException(
        'SurfaceFlinger returned no frame timings on this device.',
      );
    }
    return best;
  }

  Future<List<String>> _layersOf(String serial, String package) async {
    final list = await _shell(serial, 'dumpsys SurfaceFlinger --list');
    return list
        .splitLines()
        .map((l) => l.trim())
        .where((l) => l.contains(package))
        // Input sinks and activity records never hold buffers.
        .where((l) => !l.contains('InputSink') && !l.startsWith('Activity'))
        .where((l) => !l.startsWith('AppWindowToken'))
        .toList();
  }

  Future<String> _shell(String serial, String command) async =>
      (await _adb.run(['-s', serial, 'shell', command])).stdout.toString();
}
