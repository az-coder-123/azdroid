import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_counter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockExecutor extends Mock implements ProcessExecutor {}

void main() {
  late _MockExecutor executor;

  setUp(() => executor = _MockExecutor());

  McpProcessCounter counter(HostOs os) => McpProcessCounter(
    processExecutor: executor,
    tools: HostProcessTools.forHost(os),
    executableName: os.executableName('deskdroid-mcp'),
  );

  void result(int exit, String out) =>
      when(() => executor.run(any(), any(), timeout: any(named: 'timeout')))
          .thenAnswer((_) async => ProcessResult(1, exit, out, ''));

  test('pgrep: PIDs are counted, exit 1 means none', () async {
    result(0, '101\n202\n');
    expect(await counter(HostOs.macos).count(), 2);
    result(1, '');
    expect(await counter(HostOs.macos).count(), 0);
  });

  test('a failing process list gives no count', () async {
    result(2, '');
    expect(await counter(HostOs.macos).count(), isNull);
  });

  test('tasklist rows are counted on Windows', () async {
    result(0, '"deskdroid-mcp.exe","4120","Console","1","12,340 K"\n');
    expect(await counter(HostOs.windows).count(), 1);
  });
}
