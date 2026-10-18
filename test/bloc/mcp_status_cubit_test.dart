import 'package:bloc_test/bloc_test.dart';
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

  setUp(() {
    repository = _MockRepository();
    when(repository.load).thenAnswer((_) async => ready);
    when(repository.countRunningSessions).thenAnswer((_) async => 0);
  });

  McpStatusCubit build({Duration poll = const Duration(hours: 1)}) =>
      McpStatusCubit(repository: repository, pollInterval: poll);

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
    'polling updates only the session count',
    setUp: () =>
        when(repository.countRunningSessions).thenAnswer((_) async => 2),
    build: () => build(poll: const Duration(milliseconds: 10)),
    act: (cubit) => cubit.load(),
    wait: const Duration(milliseconds: 60),
    expect: () => [
      const McpStatusLoading(),
      McpStatusLoaded(status: ready),
      McpStatusLoaded(status: ready.copyWith(runningSessions: 2)),
    ],
    verify: (_) => verify(repository.load).called(1),
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
