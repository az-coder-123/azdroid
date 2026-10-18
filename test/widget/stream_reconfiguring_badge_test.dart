import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/pending_stream_change.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_reconfiguring_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBadge(
    WidgetTester tester,
    double width, {
    PendingStreamChange change = const BitrateChange(16),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: StreamReconfiguringBadge(change: change),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('names the bitrate being applied', (tester) async {
    await pumpBadge(tester, 300);

    expect(find.text('Applying 16 Mbps…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('names the stay-awake change being applied', (tester) async {
    await pumpBadge(tester, 300, change: const StayAwakeChange(enabled: true));
    expect(find.text('Keeping the phone awake…'), findsOneWidget);

    await pumpBadge(tester, 300, change: const StayAwakeChange(enabled: false));
    expect(find.text('Letting the phone sleep…'), findsOneWidget);
  });

  testWidgets('does not overflow in a narrow space', (tester) async {
    await pumpBadge(tester, 80);

    expect(tester.takeException(), isNull);
  });
}
