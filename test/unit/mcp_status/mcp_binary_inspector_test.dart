import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_mcp_file_probe.dart';

class _MockExecutor extends Mock implements ProcessExecutor {}

class _MockProcess extends Mock implements Process {}

void main() {
  const exe = '/Applications/DeskDroid.app/Contents/MacOS/deskdroid-mcp';
  late _MockExecutor executor;
  late List<String> sentToServer;

  setUpAll(() => registerFallbackValue(ProcessSignal.sigterm));

  setUp(() {
    executor = _MockExecutor();
    sentToServer = [];
  });

  void answerQuery(String executable, {String out = '', int exit = 0}) {
    when(() => executor.run(executable, any(), timeout: any(named: 'timeout')))
        .thenAnswer((_) async => ProcessResult(1, exit, out, ''));
  }

  /// The server process replies [reply] once stdin closes.
  void serverReplies(String reply) {
    final process = _MockProcess();
    final stdin = StreamController<List<int>>();
    addTearDown(stdin.close);
    stdin.stream.listen((b) => sentToServer.add(utf8.decode(b)));
    when(() => process.stdin).thenReturn(IOSink(stdin.sink));
    when(() => process.stdout)
        .thenAnswer((_) => Stream.value(utf8.encode(reply)));
    when(() => process.stderr).thenAnswer((_) => const Stream.empty());
    when(() => process.kill(any())).thenReturn(true);
    when(() => executor.start(exe, any())).thenAnswer((_) async => process);
  }

  McpBinaryInspector inspector({
    HostOs os = HostOs.macos,
    bool exists = true,
  }) => McpBinaryInspector(
    executablePath: exe,
    processExecutor: executor,
    tools: HostProcessTools.forHost(os),
    files: FakeMcpFileProbe(files: {if (exists) exe: ''}),
  );

  test('missing executable is reported without running anything', () async {
    final status = await inspector(exists: false).inspect();
    expect(status.availability, McpBinaryAvailability.missing);
    verifyZeroInteractions(executor);
  });

  test('a universal server that answers tools/list is ready', () async {
    answerQuery('/usr/bin/lipo', out: 'x86_64 arm64\n');
    serverReplies('{"jsonrpc":"2.0","id":1,"result":{"tools":[]}}');

    final status = await inspector().inspect();

    expect(status.availability, McpBinaryAvailability.ready);
    expect(status.architectures, ['x86_64', 'arm64']);
    expect(status.runsTranslated, isFalse);
    expect(sentToServer.join(), contains('"tools/list"'));
    verifyNever(
      () => executor.run(
        '/usr/sbin/sysctl',
        any(),
        timeout: any(named: 'timeout'),
      ),
    );
  });

  test(
    'Intel-only on Apple Silicon runs translated when Rosetta works',
    () async {
      answerQuery('/usr/bin/lipo', out: 'x86_64');
      answerQuery('/usr/sbin/sysctl', out: '1');
      serverReplies('{"result":{"tools":[]}}');

      final status = await inspector().inspect();
      expect(status.availability, McpBinaryAvailability.ready);
      expect(status.runsTranslated, isTrue);
    },
  );

  test('Intel-only on Apple Silicon that cannot start needs Rosetta', () async {
    answerQuery('/usr/bin/lipo', out: 'x86_64');
    answerQuery('/usr/sbin/sysctl', out: '1');
    when(() => executor.start(exe, any()))
        .thenThrow(const ProcessException(exe, [], 'Bad CPU type', 86));

    final status = await inspector().inspect();
    expect(status.availability, McpBinaryAvailability.needsRosetta);
  });

  test(
    'an Intel Mac (no hw.optional.arm64) runs Intel builds natively',
    () async {
      answerQuery('/usr/bin/lipo', out: 'x86_64');
      answerQuery('/usr/sbin/sysctl', exit: 1);
      serverReplies('garbage');

      final status = await inspector().inspect();
      expect(status.runsTranslated, isFalse);
      expect(status.availability, McpBinaryAvailability.notResponding);
    },
  );

  test('Windows skips the architecture checks', () async {
    serverReplies('{"result":{"tools":[]}}');
    final status = await inspector(os: HostOs.windows).inspect();
    expect(status.availability, McpBinaryAvailability.ready);
    expect(status.architectures, isEmpty);
    verifyNever(
      () => executor.run(any(), any(), timeout: any(named: 'timeout')),
    );
  });
}
