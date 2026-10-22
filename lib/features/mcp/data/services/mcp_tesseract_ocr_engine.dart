import 'dart:io';

import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp/data/services/mcp_tesseract_parser.dart';
import 'package:desk_droid/features/mcp/domain/entities/mcp_ocr_element.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_ocr_engine.dart';

/// Concrete [McpOcrEngine] using the host system's Tesseract binary.
class McpTesseractOcrEngine implements McpOcrEngine {
  McpTesseractOcrEngine({
    HostToolchain? toolchain,
    HostPaths? paths,
    this.executor = const DefaultProcessExecutor(),
    this.parser = const McpTesseractParser(),
    this.fileExists = _defaultFileExists,
  }) : toolchain = toolchain ?? HostToolchain.current(),
       paths = paths ?? SystemHostPaths();

  final HostToolchain toolchain;
  final HostPaths paths;
  final ProcessExecutor executor;
  final McpTesseractParser parser;
  final Future<bool> Function(String path) fileExists;

  static Future<bool> _defaultFileExists(String path) => File(path).exists();

  String? _resolvedExecutable;

  @override
  Future<bool> isAvailable() async {
    final exec = await _locateExecutable();
    return exec != null;
  }

  @override
  Future<List<McpOcrElement>> recognize(List<int> imageBytes) async {
    if (imageBytes.isEmpty) return const [];

    final executable = await _locateExecutable();
    if (executable == null) return const [];

    final tempDir = paths.tempDirectory;
    final tempFileName =
        'ocr_frame_${DateTime.now().microsecondsSinceEpoch}.png';
    final tempFilePath = paths.context.join(tempDir, tempFileName);
    final tempFile = File(tempFilePath);

    try {
      await tempFile.writeAsBytes(imageBytes, flush: true);

      final result = await executor.run(executable, [
        tempFilePath,
        'stdout',
        'tsv',
      ], timeout: const Duration(seconds: 10));

      if (result.exitCode != 0) return const [];

      final stdoutText = result.stdout.toString();
      return parser.parseTsv(stdoutText);
    } catch (_) {
      return const [];
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<String?> _locateExecutable() async {
    if (_resolvedExecutable != null) return _resolvedExecutable;

    // 1. Try finding on PATH using which / where
    final lookup = toolchain.pathLookupCommand;
    final name = toolchain.tesseractExecutable;
    try {
      final result = await executor.run(lookup, [name]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().splitLines();
        final path = lines.isEmpty ? '' : lines.first.trim();
        if (path.isNotEmpty && await fileExists(path)) {
          _resolvedExecutable = path;
          return path;
        }
      }
    } catch (_) {}

    // 2. Check well-known system install locations
    for (final candidate in toolchain.tesseractSearchPaths) {
      if (await fileExists(candidate)) {
        _resolvedExecutable = candidate;
        return candidate;
      }
    }

    // 3. Last resort bare invocation probe
    try {
      final probe = await executor.run(name, ['--version']);
      if (probe.exitCode == 0) {
        _resolvedExecutable = name;
        return name;
      }
    } catch (_) {}

    return null;
  }
}
