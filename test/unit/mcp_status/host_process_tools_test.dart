import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS', () {
    final tools = HostProcessTools.forHost(HostOs.macos);

    test('checks architectures with lipo and Apple Silicon with sysctl', () {
      expect(tools.binaryArchitectures?.executable, '/usr/bin/lipo');
      expect(tools.appleSiliconCheck?.arguments, ['-n', 'hw.optional.arm64']);
    });

    test('pgrep matches the precompiled server and the source entry', () {
      final command = tools.processList(
        executableName: 'azdroid-mcp',
        scriptName: 'azdroid_mcp.dart',
      );
      expect(command.executable, '/usr/bin/pgrep');
      expect(command.arguments, ['-f', 'azdroid-mcp|azdroid_mcp.dart']);
    });

    test('reads one PID per line', () {
      expect(tools.parsePids('123\n456\n\n', executableName: 'azdroid-mcp'), {
        123,
        456,
      });
      expect(tools.parsePids('', executableName: 'azdroid-mcp'), isEmpty);
    });
  });

  group('Windows', () {
    final tools = HostProcessTools.forHost(HostOs.windows);

    test('has no architecture or Rosetta checks', () {
      expect(tools.binaryArchitectures, isNull);
      expect(tools.appleSiliconCheck, isNull);
    });

    test('tasklist filters by image name, as CSV', () {
      final command = tools.processList(
        executableName: 'azdroid-mcp.exe',
        scriptName: 'azdroid_mcp.dart',
      );
      expect(command.executable, 'tasklist');
      expect(command.arguments, contains('IMAGENAME eq azdroid-mcp.exe'));
    });

    test('reads the PID column and ignores the "no tasks" message', () {
      const rows =
          '"azdroid-mcp.exe","4120","Console","1","12,340 K"\r\n'
          '"Azdroid-MCP.exe","4188","Console","1","12,100 K"\r\n';
      expect(tools.parsePids(rows, executableName: 'azdroid-mcp.exe'), {
        4120,
        4188,
      });
      expect(
        tools.parsePids(
          'INFO: No tasks are running which match the specified criteria.',
          executableName: 'azdroid-mcp.exe',
        ),
        isEmpty,
      );
    });
  });
}
