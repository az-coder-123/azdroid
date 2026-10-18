import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mcp_status_fixtures.dart';

class _MockRepository extends Mock implements McpStatusRepository {}

void main() {
  late _MockRepository repository;
  final ready = mcpStatus();
  final activity = McpActivitySnapshot(
    recent: [
      McpActivityEntry(
        pid: 7,
        clientName: 'claude-ai',
        event: McpActivityEvent.toolCall(
          at: DateTime.utc(2026, 10, 18),
          tool: 'android_tap',
          deviceSerial: 'R9',
          succeeded: true,
          durationMs: 50,
        ),
      ),
    ],
  );

  setUp(() {
    repository = _MockRepository();
    when(repository.load).thenAnswer((_) async => ready);
    when(repository.listServerPids).thenAnswer((_) async => const {});
    when(() => repository.readActivity(livePids: any(named: 'livePids')))
        .thenAnswer((_) async => const McpActivitySnapshot());
  });

  McpStatusCubit build({
    Duration sessions = const Duration(hours: 1),
    Duration activity = const Duration(hours: 1),
  }) => McpStatusCubit(
    repository: repository,
    sessionPollInterval: sessions,
    activityPollInterval: activity,
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'the first load shows loading, then the status',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const McpStatusLoading(), McpStatusLoaded(status: ready)],
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'a refresh keeps the previous status visible while it runs',
    build: build,
    seed: () => McpStatusLoaded(status: ready),
    act: (cubit) => cubit.load(),
    expect: () => [
      McpStatusLoaded(status: ready, isRefreshing: true),
      McpStatusLoaded(status: ready),
    ],
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'a second load while one runs is ignored',
    build: build,
    act: (cubit) => cubit
      ..load()
      ..load(),
    expect: () => [const McpStatusLoading(), McpStatusLoaded(status: ready)],
    verify: (_) => verify(repository.load).called(1),
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'session polling updates only the live processes, once per change',
    setUp: () =>
        when(repository.listServerPids).thenAnswer((_) async => {7, 8}),
    build: () => build(sessions: const Duration(milliseconds: 10)),
    act: (cubit) => cubit.load(),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      const McpStatusLoading(),
      McpStatusLoaded(status: ready),
      McpStatusLoaded(status: ready.copyWith(livePids: {7, 8})),
    ],
    verify: (_) => verify(repository.load).called(1),
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'activity polling publishes new tool calls',
    setUp: () =>
        when(() => repository.readActivity(livePids: any(named: 'livePids')))
            .thenAnswer((_) async => activity),
    build: () => build(activity: const Duration(milliseconds: 10)),
    act: (cubit) => cubit.load(),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      const McpStatusLoading(),
      McpStatusLoaded(status: ready),
      McpStatusLoaded(status: ready.copyWith(activity: activity)),
    ],
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'a failing poll keeps the last status',
    setUp: () =>
        when(repository.listServerPids).thenThrow(Exception('pgrep gone')),
    build: () => build(sessions: const Duration(milliseconds: 10)),
    act: (cubit) => cubit.load(),
    wait: const Duration(milliseconds: 40),
    expect: () => [const McpStatusLoading(), McpStatusLoaded(status: ready)],
  );

  blocTest<McpStatusCubit, McpStatusState>(
    'an unexpected error becomes a failure state',
    setUp: () => when(repository.load).thenThrow(Exception('boom')),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const McpStatusLoading(),
      isA<McpStatusFailure>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );
}
