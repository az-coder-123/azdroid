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
    ValueChanged<int>? onSelectBitrate,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: StreamSettingsControls(
          session: session,
          onSelectBitrate: onSelectBitrate,
        ),
      ),
    ),
  );

  testWidgets('renders bitrate popup button with tune icon', (tester) async {
    await pump(tester, onSelectBitrate: (_) {});

    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byTooltip('Streaming Bitrate & Quality'), findsOneWidget);
  });

  testWidgets('tapping bitrate button opens menu with options', (tester) async {
    int? selectedBitrate;
    await pump(tester, onSelectBitrate: (b) => selectedBitrate = b);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('4 Mbps (Eco / Weak Wi-Fi)'), findsOneWidget);
    expect(find.text('8 Mbps (Standard 1080p)'), findsOneWidget);
    expect(find.text('16 Mbps (Ultra / 60+ FPS)'), findsOneWidget);

    await tester.tap(find.text('16 Mbps (Ultra / 60+ FPS)'));
    await tester.pumpAndSettle();

    expect(selectedBitrate, 16);
  });

  testWidgets('the button is disabled while change applies', (tester) async {
    await pump(tester, onSelectBitrate: null);

    final button = tester.widget<PopupMenuButton<int>>(
      find.byType(PopupMenuButton<int>),
    );
    expect(button.enabled, isFalse);
  });
}
