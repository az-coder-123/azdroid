import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/features/mcp/data/handlers/mcp_tool_executor.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_server_instructions.dart';
import 'package:desk_droid/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the MCP tool catalog single source of truth
/// (`lib/features/mcp/domain/services/mcp_*_tools.dart`):
///
/// 1. Registry tool names must be unique.
/// 2. Every tool published via `tools/list` must route to an executor
///    implementation (no dead catalog entries).
/// 3. Every published tool must have a synchronized client manifest in
///    `.agents/mcp/azdroid/` (name, description, and parameters must match
///    the registry definition) to prevent silent drift.
/// 4. No orphan manifest files may exist without a registry tool.
void main() {
  const manifestDir = '.agents/mcp/azdroid';

  final tools = const McpToolRegistry().getTools();
  final executor = McpToolExecutor();

  test('registry publishes unique tool names', () {
    final names = tools.map((t) => t.name).toList();
    final duplicates = names.toSet().toList();

    expect(
      names.length,
      duplicates.length,
      reason: 'Duplicate tool names found in McpToolRegistry.',
    );
  });

  test('every registry tool routes to an executor', () {
    final unroutable = [
      for (final tool in tools)
        if (!executor.canHandle(tool.name)) tool.name,
    ];

    expect(
      unroutable,
      isEmpty,
      reason:
          'Tools published via tools/list but missing an executor '
          'implementation: $unroutable',
    );
  });

  test('every registry tool has a synchronized client manifest', () {
    final mismatches = <String>[];
    for (final tool in tools) {
      final file = File('$manifestDir/${tool.name}.json');
      if (!file.existsSync()) {
        mismatches.add('${tool.name}: missing manifest file');
        continue;
      }

      final dynamic manifest = jsonDecode(file.readAsStringSync());
      if (manifest is! Map<String, dynamic>) {
        mismatches.add('${tool.name}: manifest is not a JSON object');
        continue;
      }

      expect(
        manifest['name'],
        tool.name,
        reason: '${tool.name}: manifest "name" differs from registry.',
      );
      expect(
        manifest['description'],
        tool.description,
        reason: '${tool.name}: manifest "description" differs from registry.',
      );
      expect(
        manifest['parameters'],
        tool.inputSchema,
        reason:
            '${tool.name}: manifest "parameters" differ from registry '
            'inputSchema.',
      );
      expect(
        manifest['annotations'],
        tool.annotations,
        reason:
            '${tool.name}: manifest "annotations" differ from registry. '
            'Run: dart run tool/generate_mcp_manifests.dart',
      );
    }

    expect(mismatches, isEmpty, reason: mismatches.join('\n'));
  });

  test('no orphan manifest files without a registry tool', () {
    final registered = tools.map((t) => t.name).toSet();
    final orphans = Directory(manifestDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .map((name) => name.substring(0, name.length - '.json'.length))
        .where((name) => !registered.contains(name))
        .toList();

    expect(
      orphans,
      isEmpty,
      reason: 'Manifest files referencing unregistered tools: $orphans',
    );
  });

  test('every tool carries explicit safety annotations', () {
    final unannotated = [
      for (final tool in tools)
        if (tool.annotations == null) tool.name,
    ];

    expect(
      unannotated,
      isEmpty,
      reason:
          'Tools without annotations default to destructiveHint=true in '
          'clients. Add a preset from mcp_tool_annotations.dart: '
          '$unannotated',
    );
  });

  test('destructive tools match the reviewed allowlist', () {
    const destructiveAllowlist = {
      'android_clear_app_data',
      'android_dismiss_notification',
      'android_install_apk',
      'android_kill_process',
      'android_shell_command',
      'android_stop_app',
      // Reviewed 2026-10-22: replay-safe, but they cut a Wi-Fi ADB link,
      // kill the app, or overwrite files (destructiveStateSetToolAnnotations).
      'android_toggle_wifi',
      'android_toggle_airplane_mode',
      'android_set_network_condition',
      'android_revoke_permission',
      'android_push_file',
      'android_pull_file',
    };

    final flagged = {
      for (final tool in tools)
        if (tool.annotations?['destructiveHint'] == true) tool.name,
    };

    expect(
      flagged,
      equals(destructiveAllowlist),
      reason:
          'destructiveHint requires review: newly flagged=$flagged. '
          'Update the allowlist only with explicit approval.',
    );
  });

  test('the server instructions name every destructive tool', () {
    final unmentioned = [
      for (final tool in tools)
        if (tool.annotations?['destructiveHint'] == true &&
            !mcpServerInstructions.contains(tool.name))
          tool.name,
    ];

    expect(
      unmentioned,
      isEmpty,
      reason:
          'Agents read mcp_server_instructions.dart before any call; every '
          'destructive tool must be listed there as needing confirmation: '
          '$unmentioned',
    );
  });

  test('annotation hint keys are valid and coherent', () {
    const validHints = {'readOnlyHint', 'destructiveHint', 'idempotentHint'};

    for (final tool in tools) {
      final annotations = tool.annotations!;
      expect(
        annotations.keys.toSet().difference(validHints),
        isEmpty,
        reason:
            '${tool.name}: unknown annotation hints '
            '${annotations.keys.toSet().difference(validHints)}.',
      );
      expect(
        annotations['readOnlyHint'],
        isA<bool>(),
        reason: '${tool.name}: readOnlyHint must be a bool.',
      );
      expect(
        annotations['destructiveHint'],
        isA<bool>(),
        reason: '${tool.name}: destructiveHint must be a bool.',
      );
      expect(
        annotations['idempotentHint'],
        isA<bool>(),
        reason: '${tool.name}: idempotentHint must be a bool.',
      );

      if (annotations['readOnlyHint'] == true) {
        expect(
          annotations['destructiveHint'],
          isFalse,
          reason: '${tool.name}: a readOnlyHint tool cannot be destructive.',
        );
      }
    }
  });
}
