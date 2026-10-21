import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_lister.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockExecutor extends Mock implements ProcessExecutor {}

void main() {
  late _MockExecutor executor;

  setUp(() => executor = _MockExecutor());

  McpProcessLister lister(HostOs os) => McpProcessLister(
    processExecutor: executor,
    tools: HostProcessTools.forHost(os),
    executableName: os.executableName('azdroid-mcp'),
  );

  void result(int exit, String out) =>
      when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => ProcessResult(1, exit, out, ''));

  test('pgrep: PIDs are listed, exit 1 means none', () async {
    result(0, '101\n202\n');
    expect(await lister(HostOs.macos).listPids(), {101, 202});
    result(1, '');
    expect(await lister(HostOs.macos).listPids(), isEmpty);
  });

  test('a failing process list gives no count', () async {
    result(2, '');
    expect(await lister(HostOs.macos).listPids(), isNull);
  });

  test('tasklist rows give their PIDs on Windows', () async {
    result(0, '"azdroid-mcp.exe","4120","Console","1","12,340 K"\r\n');
    expect(await lister(HostOs.windows).listPids(), {4120});
  });
}
