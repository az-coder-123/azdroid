import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/models/mcp_activity_event.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_activity_section.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_device_activity_banner.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mcp_status_fixtures.dart';

class _MockCubit extends MockCubit<McpStatusState> implements McpStatusCubit {}

void main() {
  const serial = '192.168.1.3:5555';
  final at = DateTime.now();
  final tap = McpActivityEntry(
    pid: 7,
    clientName: 'claude-ai',
    event: McpActivityEvent.toolCall(
      at: at,
      tool: 'android_tap',
      deviceSerial: serial,
      succeeded: true,
      durationMs: 85,
    ),
  );
  final active = McpActivitySnapshot(
    sessions: [
      McpSessionActivity(
        pid: 7,
        clientName: 'claude-ai',
        startedAt: at,
        lastCall: tap.event,
      ),
    ],
    recent: [tap],
    activeByDevice: {serial: tap},
  );

  Widget host(Widget child, {McpStatusCubit? cubit}) => MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: cubit == null
          ? child
          : BlocProvider<McpStatusCubit>.value(value: cubit, child: child),
    ),
  );

  _MockCubit cubitWith(McpActivitySnapshot activity) {
    final cubit = _MockCubit();
    when(() => cubit.state).thenReturn(
      McpStatusLoaded(
        status: mcpStatus(livePids: {7}, activity: activity),
      ),
    );
    return cubit;
  }

  testWidgets('the panel section lists sessions and recent calls', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SingleChildScrollView(child: McpActivitySection(activity: active))),
    );
    expect(find.textContaining('claude-ai (since'), findsOneWidget);
    expect(
      find.textContaining('android_tap on $serial · 85 ms'),
      findsNWidgets(2),
    );
    expect(find.textContaining('never what the AI types'), findsOneWidget);
  });

  testWidgets('an empty section says no calls yet', (tester) async {
    await tester.pumpWidget(
      host(const McpActivitySection(activity: McpActivitySnapshot())),
    );
    expect(find.textContaining('No tool calls yet'), findsOneWidget);
  });

  testWidgets('the banner shows only on the device the AI uses', (
    tester,
  ) async {
    final cubit = cubitWith(active);
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            McpDeviceActivityBanner(deviceSerial: serial),
            McpDeviceActivityBanner(deviceSerial: 'other:5555'),
          ],
        ),
        cubit: cubit,
      ),
    );
    expect(
      find.text('claude-ai is controlling this device · android_tap'),
      findsOneWidget,
    );
  });

  testWidgets('the banner renders nothing without the cubit', (tester) async {
    await tester.pumpWidget(
      host(const McpDeviceActivityBanner(deviceSerial: serial)),
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the toolbar tooltip names what the AI is doing', (tester) async {
    final cubit = cubitWith(active);
    await tester.pumpWidget(host(const McpStatusIndicator(), cubit: cubit));
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).tooltip,
      'MCP server: claude-ai is using android_tap on $serial',
    );
  });
}
