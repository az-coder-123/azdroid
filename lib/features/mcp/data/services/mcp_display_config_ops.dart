import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_shell_result.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';

/// Changes how the device renders apps, so an agent can check a layout in
/// dark mode, with large text, or on another screen size without another
/// phone. Every setting stays until changed back or [reset].
class McpDisplayConfigOps {
  const McpDisplayConfigOps(this._adb);

  final McpAdbClient _adb;

  static const Set<String> nightModes = {'yes', 'no', 'auto'};

  /// Applies the given settings, then reads all of them back.
  Future<String> apply(
    String serial, {
    String? nightMode,
    double? fontScale,
    String? density,
    String? size,
    bool reset = false,
  }) async {
    if (nightMode != null && !nightModes.contains(nightMode)) {
      throw McpArgumentException(
        'nightMode must be one of ${nightModes.join(', ')}.',
      );
    }
    if (fontScale != null && (fontScale < 0.5 || fontScale > 3)) {
      throw const McpArgumentException('fontScale must be within 0.5–3.0.');
    }
    if (density != null &&
        density != 'reset' &&
        int.tryParse(density) == null) {
      throw const McpArgumentException('density is a dpi number or "reset".');
    }
    if (size != null &&
        size != 'reset' &&
        !RegExp(r'^\d+x\d+$').hasMatch(size)) {
      throw const McpArgumentException('size is WIDTHxHEIGHT or "reset".');
    }
    final commands = [
      if (reset) ...[
        'cmd uimode night no',
        'settings put system font_scale 1.0',
        'wm density reset',
        'wm size reset',
      ],
      if (nightMode != null) 'cmd uimode night $nightMode',
      if (fontScale != null) 'settings put system font_scale $fontScale',
      if (density != null) 'wm density $density',
      if (size != null) 'wm size $size',
    ];
    if (commands.isEmpty) {
      throw const McpArgumentException(
        'Give nightMode, fontScale, density, size, or reset: true.',
      );
    }
    for (final command in commands) {
      final res = await _adb.run(['-s', serial, 'shell', command]);
      if (!res.succeeded) {
        return 'Failed: `$command`: ${res.stdout} ${res.stderr}'.trim();
      }
    }
    return 'Applied ${commands.length} change(s). Now:\n'
        '${await current(serial)}';
  }

  /// The current settings, as the device reports them.
  Future<String> current(String serial) async {
    final res = await _adb.run([
      '-s',
      serial,
      'shell',
      'cmd uimode night; echo "Font scale: \$(settings get system font_scale)"; '
          'wm density; wm size',
    ]);
    return res.stdout.toString().trim();
  }
}
