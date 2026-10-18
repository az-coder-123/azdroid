import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/mcp_activity_paths.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_activity_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mcp_status/fake_mcp_file_probe.dart';

void main() {
  final paths = McpActivityPaths(
    SystemHostPaths(
      os: HostOs.macos,
      environment: const {'HOME': '/Users/dev'},
      systemTempPath: '/tmp',
    ),
  );
  final dir = paths.directory;
  final now = DateTime.utc(2026, 10, 18, 12);
  final call = McpActivityEvent.toolCall(
    at: now,
    tool: 'android_tap',
    deviceSerial: 'R9',
    succeeded: true,
    durationMs: 5,
  );

  test('the folder is under the app data folder', () {
    expect(
      dir,
      '/Users/dev/Library/Application Support/DeskDroid/mcp-activity',
    );
    expect(paths.pidOf(paths.fileFor(77)), 77);
    expect(paths.pidOf('$dir/notes.txt'), isNull);
  });

  test('reads every session file and skips broken lines', () async {
    final files = FakeMcpFileProbe(
      files: {
        paths.fileFor(1): '${call.toLine()}\n{"kind":"tool","at":',
        paths.fileFor(2): '',
        '$dir/readme.txt': 'ignored',
        paths.fileFor(3): null, // Deleted between listing and reading.
      },
    );
    final events = await McpActivityReader(
      paths: paths,
      files: files,
    ).readAll();
    expect(events, {
      1: [call],
      2: <McpActivityEvent>[],
    });
  });

  test('prunes only old files of processes that no longer run', () async {
    final files = FakeMcpFileProbe(
      files: {paths.fileFor(1): '', paths.fileFor(2): '', paths.fileFor(3): ''},
      modified: {
        paths.fileFor(1): now.subtract(const Duration(hours: 1)),
        paths.fileFor(2): now.subtract(const Duration(hours: 1)),
        paths.fileFor(3): now.subtract(const Duration(minutes: 1)),
      },
    );
    await McpActivityReader(
      paths: paths,
      files: files,
    ).pruneStale(livePids: {2}, now: now);
    expect(files.deleted, [paths.fileFor(1)]);
  });
}
