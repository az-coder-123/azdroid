import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guards the rule from `docs/platform-abstraction.md`: OS differences live
/// only in `lib/core/platform/` and its DI module. Everything else must use
/// the contracts, so macOS and Windows stay equally maintainable.
void main() {
  const allowedPrefixes = ['lib/core/platform/'];
  const allowedFiles = ['lib/core/di/modules/platform_di.dart'];

  final forbidden = <String, RegExp>{
    'OS check or environment read (use HostOs / HostPaths / HostToolchain)':
        RegExp(
          r'\bPlatform\.(is[A-Z]\w*|environment|operatingSystem|pathSeparator)\b',
        ),
    'Hard-coded host tool path (add it to HostToolchain)': RegExp(
      r"""['"](/usr/s?bin/|/opt/homebrew/|C:\\\\)""",
    ),
    'macOS-only shell tool (wrap it in a core/platform strategy)': RegExp(
      r"""['"](osascript|pbcopy|pbpaste|/usr/bin/open)['"]""",
    ),
    'Raw newline split on text (use splitLines())': RegExp(r"split\('\\n'\)"),
  };

  bool isAllowed(String path) =>
      allowedFiles.contains(path) ||
      allowedPrefixes.any((prefix) => path.startsWith(prefix));

  Iterable<File> dartFiles(String root) =>
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

  for (final MapEntry(key: rule, value: pattern) in forbidden.entries) {
    test('no "$rule" outside lib/core/platform', () {
      final violations = <String>[];
      for (final file in [...dartFiles('lib'), ...dartFiles('bin')]) {
        final path = p.posix.joinAll(p.split(file.path));
        if (isAllowed(path)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//')) continue;
          if (pattern.hasMatch(line)) violations.add('$path:${i + 1}: $line');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
