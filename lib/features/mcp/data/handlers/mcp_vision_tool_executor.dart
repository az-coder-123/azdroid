import 'dart:io';
import 'dart:typed_data';

import 'package:desk_droid/features/mcp/data/services/mcp_adb_client.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_gray_image.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_template_matcher.dart';
import 'package:desk_droid/features/mcp/data/utils/mcp_argument_helper.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_tool_definition.dart';
import 'package:image/image.dart' as img;

/// Screen-image operations for screens without an accessibility tree
/// (games, canvases, video): find a picture, wait for one, or wait until
/// the screen changes.
///
/// Templates come from an image file on the computer (a game asset) or
/// from a region of the screen saved under a name ([_templates], kept in
/// memory for the life of the server process; nothing is written to disk).
class McpVisionToolExecutor {
  McpVisionToolExecutor(this._adb);

  final McpAdbClient _adb;
  final Map<String, img.Image> _templates = {};

  /// Saved templates kept at once; the oldest is dropped beyond this.
  static const int maxSavedTemplates = 20;

  /// Width of the copy compared by `screen_changed`.
  static const int changeSampleWidth = 120;

  bool canHandle(String toolName) =>
      toolName == 'android_find_image' || toolName == 'android_wait_for_screen';

  Future<McpToolResult> execute(
    String toolName,
    String serial,
    Map<String, dynamic> arguments,
  ) async {
    final timeoutMs = arguments.getInt('timeoutMs', defaultValue: 10000);
    final pollMs = arguments.getInt('pollIntervalMs', defaultValue: 500);
    final threshold = arguments.getDouble('threshold', defaultValue: 0.8);
    if (toolName == 'android_find_image' &&
        arguments.getString('saveAs') != null) {
      return _saveTemplate(serial, arguments);
    }
    return switch (toolName == 'android_find_image'
        ? 'image_present_once'
        : arguments.getRequiredString('condition')) {
      'image_present_once' => _findImage(serial, arguments, threshold),
      'image_present' => _poll(timeoutMs, pollMs, () async {
        final r = await _findImage(serial, arguments, threshold);
        return r.isError ? null : r;
      }, () => 'image_present'),
      'screen_changed' => _waitForChange(serial, arguments, timeoutMs, pollMs),
      final other => Future.value(
        McpToolResult.error('Unknown condition "$other".'),
      ),
    };
  }

  Future<McpToolResult> _findImage(
    String serial,
    Map<String, dynamic> arguments,
    double threshold,
  ) async {
    final (path, template) = await _template(arguments);
    final screen = await _screen(serial);
    final match = McpTemplateMatcher.find(
      screen,
      template,
      threshold: threshold,
      scale: arguments.getOptionalDouble('scale'),
    );
    final where =
        'center (${match.centerX}, ${match.centerY}) px = ratio '
        '(${(match.centerX / screen.width).toStringAsFixed(4)}, '
        '${(match.centerY / screen.height).toStringAsFixed(4)}), box '
        '${match.left},${match.top} ${match.width}×${match.height}, score '
        '${match.score.toStringAsFixed(3)}, scale ${match.scale}';
    return match.score >= threshold
        ? McpToolResult.text(
            'Found $path at $where.\nTap it with android_tap(xPixel: '
            '${match.centerX}, yPixel: ${match.centerY}).',
          )
        : McpToolResult.error(
            'Not found (threshold $threshold). Best candidate: $where.',
          );
  }

  /// The template named by `templateName`, or read from `templatePath`.
  Future<(String, img.Image)> _template(Map<String, dynamic> args) async {
    final name = args.getString('templateName');
    if (name != null) {
      final saved = _templates[name];
      if (saved == null) {
        throw McpArgumentException(
          'No saved template "$name" (saved: '
          '${_templates.keys.isEmpty ? 'none' : _templates.keys.join(', ')}). '
          'Save one with saveAs and a screen region.',
        );
      }
      return ('template "$name"', saved);
    }
    final path = args.getString(
      'templatePath',
      aliases: ['imagePath', 'template'],
    );
    if (path == null) {
      throw const McpArgumentException(
        'Give templatePath (an image file) or templateName (saved earlier).',
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      throw McpArgumentException('Template file not found: $path');
    }
    final image = img.decodeImage(await file.readAsBytes());
    if (image == null) {
      throw McpArgumentException('Cannot decode $path (PNG or JPEG).');
    }
    return (path, image);
  }

  /// Saves a region of the current screen as template `saveAs`.
  Future<McpToolResult> _saveTemplate(
    String serial,
    Map<String, dynamic> args,
  ) async {
    final name = args.getRequiredString('saveAs');
    final screen = await _screen(serial);
    int edge(String key, int extent) {
      final ratio = args.getOptionalDouble('${key}Ratio');
      final px = args.getOptionalDouble(key);
      final value = ratio != null ? ratio * extent : px;
      if (value == null) {
        throw const McpArgumentException(
          'saveAs needs the region: x, y, width, height in pixels or '
          'xRatio, yRatio, widthRatio, heightRatio.',
        );
      }
      return value.round();
    }

    final x = edge('x', screen.width), y = edge('y', screen.height);
    final w = edge('width', screen.width), h = edge('height', screen.height);
    if (x < 0 ||
        y < 0 ||
        w < 4 ||
        h < 4 ||
        x + w > screen.width ||
        y + h > screen.height) {
      throw McpArgumentException(
        'Region $x,$y $w×$h is outside the ${screen.width}×${screen.height} '
        'screen or smaller than 4×4.',
      );
    }
    _templates.remove(name);
    if (_templates.length >= maxSavedTemplates) {
      _templates.remove(_templates.keys.first);
    }
    _templates[name] = img.copyCrop(screen, x: x, y: y, width: w, height: h);
    return McpToolResult.text(
      'Saved template "$name" ($w×$h px from $x,$y). Find it later with '
      'android_find_image(templateName: "$name") or wait for it with '
      'android_wait_for_condition(condition: "image_present", '
      'templateName: "$name").',
    );
  }

  Future<McpToolResult> _waitForChange(
    String serial,
    Map<String, dynamic> arguments,
    int timeoutMs,
    int pollMs,
  ) async {
    final minChange = arguments.getDouble('minChange', defaultValue: 0.01);
    // The status bar (clock, icons) changes on its own.
    final ignoreTop = arguments.getDouble('ignoreTopRatio', defaultValue: 0.05);
    final baseline = McpGrayImage.thumbnail(
      await _screen(serial),
      changeSampleWidth,
    );
    var last = 0.0;
    return _poll(
      timeoutMs,
      pollMs,
      () async {
        last = baseline.changedFraction(
          McpGrayImage.thumbnail(await _screen(serial), changeSampleWidth),
          ignoreTop: ignoreTop,
        );
        return last >= minChange
            ? McpToolResult.text(
                'Screen changed: ${(last * 100).toStringAsFixed(1)}% of the '
                'screen differs.',
              )
            : null;
      },
      () => last >= minChange
          ? 'screen_changed'
          : 'screen_changed (last change ${(last * 100).toStringAsFixed(2)}%)',
    );
  }

  Future<img.Image> _screen(String serial) async {
    final bytes = await _adb.captureScreenshotBytes(serial);
    final image = bytes == null || bytes.isEmpty
        ? null
        : img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) {
      throw McpArgumentException('Failed to capture a screenshot of $serial.');
    }
    return image;
  }

  /// Runs [check] until it returns a result or [timeoutMs] passes.
  static Future<McpToolResult> _poll(
    int timeoutMs,
    int pollMs,
    Future<McpToolResult?> Function() check,
    String Function() label,
  ) async {
    final watch = Stopwatch()..start();
    while (true) {
      final result = await check();
      if (result != null) {
        return McpToolResult.text(
          'Condition "${label()}" met (${watch.elapsedMilliseconds}ms): '
          '${result.content.first.text}',
        );
      }
      if (watch.elapsedMilliseconds >= timeoutMs) {
        return McpToolResult.error(
          'Timed out after ${timeoutMs}ms waiting for ${label()}.',
        );
      }
      await Future<void>.delayed(Duration(milliseconds: pollMs));
    }
  }
}
