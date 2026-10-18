import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_binary_status.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_client_status.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mcp_status_fixtures.dart';

class _MockCubit extends MockCubit<McpStatusState> implements McpStatusCubit {}

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.configurationSnippet).thenReturn('{"mcpServers":{}}');
  });

  Future<void> pump(
    WidgetTester tester,
    McpStatusState state, {
    Size size = const Size(1000, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      BlocProvider<McpStatusCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(appBar: AppBar(actions: const [McpStatusIndicator()])),
        ),
      ),
    );
  }

  String tooltip(WidgetTester tester) =>
      tester.widget<IconButton>(find.byType(IconButton)).tooltip!;

  testWidgets('a ready server not set up anywhere asks for setup', (
    tester,
  ) async {
    await pump(
      tester,
      McpStatusLoaded(status: mcpStatus(claude: McpClientSetup.notConfigured)),
    );
    expect(tooltip(tester), 'MCP server: Ready, not set up in an AI client');
  });

  testWidgets('connected sessions show as a count badge', (tester) async {
    await pump(tester, McpStatusLoaded(status: mcpStatus(sessions: 2)));
    expect(find.text('2'), findsOneWidget);
    expect(tooltip(tester), 'MCP server: 2 AI sessions connected');
  });

  testWidgets('while checking, the tooltip says so', (tester) async {
    await pump(tester, const McpStatusLoading());
    expect(tooltip(tester), 'MCP server: checking…');
  });

  testWidgets('the panel re-checks and lists server, clients, and setup', (
    tester,
  ) async {
    await pump(tester, McpStatusLoaded(status: mcpStatus(sessions: 1)));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    verify(() => cubit.load()).called(1);
    expect(find.text('MCP Server'), findsOneWidget);
    expect(find.text(fixtureMcpExecutable), findsOneWidget);
    expect(find.text('Built for Intel (x86_64)'), findsOneWidget);
    expect(find.text('Uses another copy'), findsOneWidget);
    expect(
      find.text('Runs: dart run /src/bin/deskdroid_mcp.dart'),
      findsOneWidget,
    );
    expect(find.text('Set Up an AI Client'), findsOneWidget);
  });

  testWidgets('a debug build without the server hides the setup snippet', (
    tester,
  ) async {
    await pump(
      tester,
      McpStatusLoaded(
        status: mcpStatus(availability: McpBinaryAvailability.missing),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Set Up an AI Client'), findsNothing);
    expect(find.textContaining('start_mcp_server.sh'), findsOneWidget);
  });

  testWidgets('a short, narrow window scrolls the body and keeps the footer', (
    tester,
  ) async {
    await pump(
      tester,
      McpStatusLoaded(
        status: mcpStatus(availability: McpBinaryAvailability.needsRosetta),
      ),
      size: const Size(360, 420),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // No RenderFlex overflow.
    expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Close'));
    await tester.pumpAndSettle();
    expect(find.text('MCP Server'), findsNothing);
  });
}
