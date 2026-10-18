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
        executableName: 'deskdroid-mcp',
        scriptName: 'deskdroid_mcp.dart',
      );
      expect(command.executable, '/usr/bin/pgrep');
      expect(command.arguments, ['-f', 'deskdroid-mcp|deskdroid_mcp.dart']);
    });

    test('counts one PID per line', () {
      expect(
        tools.countMatches('123\n456\n\n', executableName: 'deskdroid-mcp'),
        2,
      );
      expect(tools.countMatches('', executableName: 'deskdroid-mcp'), 0);
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
        executableName: 'deskdroid-mcp.exe',
        scriptName: 'deskdroid_mcp.dart',
      );
      expect(command.executable, 'tasklist');
      expect(command.arguments, contains('IMAGENAME eq deskdroid-mcp.exe'));
    });

    test('counts CSV rows and ignores the "no tasks" message', () {
      const rows =
          '"deskdroid-mcp.exe","4120","Console","1","12,340 K"\r\n'
          '"DeskDroid-MCP.exe","4188","Console","1","12,100 K"\r\n';
      expect(tools.countMatches(rows, executableName: 'deskdroid-mcp.exe'), 2);
      expect(
        tools.countMatches(
          'INFO: No tasks are running which match the specified criteria.',
          executableName: 'deskdroid-mcp.exe',
        ),
        0,
      );
    });
  });
}
