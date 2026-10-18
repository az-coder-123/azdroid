import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/stream_settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = StreamSessionEntity(
    sessionId: 's',
    deviceId: 'd',
    width: 1080,
    height: 2336,
    fps: 60,
    bitrateMbps: 8,
  );

  Future<void> pump(
    WidgetTester tester, {
    required bool stayAwake,
    VoidCallback? onToggle,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: StreamSettingsControls(
          session: session.copyWith(stayAwake: stayAwake),
          onSelectBitrate: (_) {},
          onToggleStayAwake: onToggle,
        ),
      ),
    ),
  );

  testWidgets('shows the filled icon while stay awake is on', (tester) async {
    await pump(tester, stayAwake: true, onToggle: () {});

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
  });

  testWidgets('shows the outlined icon while stay awake is off', (
    tester,
  ) async {
    await pump(tester, stayAwake: false, onToggle: () {});

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('tapping the toggle calls back', (tester) async {
    var toggles = 0;
    await pump(tester, stayAwake: true, onToggle: () => toggles++);

    await tester.tap(find.byIcon(Icons.light_mode_rounded));

    expect(toggles, 1);
  });

  testWidgets('the toggle is disabled while a change applies', (tester) async {
    await pump(tester, stayAwake: true);

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.light_mode_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
