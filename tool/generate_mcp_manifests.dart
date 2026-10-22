// Regenerates the client tool manifests in `.agents/mcp/azdroid/` from the
// single source of truth (`McpToolRegistry`). Run from the project root:
//
//   dart run tool/generate_mcp_manifests.dart
//
// The guard test `test/architecture/mcp_tool_catalog_guard_test.dart` fails
// the build if the checked-in manifests ever drift from the registry.
import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/features/mcp/domain/services/mcp_tool_registry.dart';

Future<void> main() async {
  const manifestDirPath = '.agents/mcp/azdroid';
  final manifestDir = Directory(manifestDirPath);
  if (!manifestDir.existsSync()) {
    stderr.writeln('Manifest directory not found: $manifestDirPath');
    exitCode = 1;
    return;
  }

  final tools = const McpToolRegistry().getTools();
  const encoder = JsonEncoder.withIndent('  ');
  final written = <String>{};

  for (final tool in tools) {
    final manifest = <String, dynamic>{
      'name': tool.name,
      'description': tool.description,
      'parameters': tool.inputSchema,
      if (tool.annotations != null) 'annotations': tool.annotations,
    };
    final file = File('$manifestDirPath/${tool.name}.json');
    // Trailing newline: POSIX text files, clean diffs.
    await file.writeAsString('${encoder.convert(manifest)}\n');
    written.add(tool.name);
  }

  final orphans = <String>[];
  for (final entity in manifestDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last.replaceAll('.json', '');
    if (!written.contains(name)) {
      orphans.add(name);
      await entity.delete();
    }
  }

  stdout.writeln(
    'Generated ${written.length} tool manifests in $manifestDirPath.',
  );
  if (orphans.isNotEmpty) {
    stdout.writeln('Removed orphan manifests: ${orphans.join(', ')}');
  }
}
