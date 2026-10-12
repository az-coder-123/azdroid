import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/core/theme/app_theme.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/empty_state_view.dart';

void main() {
  testWidgets(
    'EmptyStateView renders titles, checklist cards and triggers callbacks',
    (WidgetTester tester) async {
      var scanPressed = false;
      var qrPressed = false;
      var guidePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: EmptyStateView(
              isScanning: false,
              onScanPressed: () => scanPressed = true,
              onPairWithQrPressed: () => qrPressed = true,
              onGuidePressed: () => guidePressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify main header and checklist cards
      expect(find.text('No Devices Discovered'), findsOneWidget);
      expect(find.text('Same Wi-Fi Network'), findsOneWidget);
      expect(find.text('Wireless Debugging'), findsOneWidget);
      expect(find.text('Pair & Connect'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Scan for Devices'), findsOneWidget);
      expect(find.text('Pair with QR Code'), findsOneWidget);
      expect(find.text('User Guide'), findsOneWidget);

      // Verify callbacks
      await tester.tap(find.text('Scan for Devices'));
      expect(scanPressed, isTrue);

      await tester.tap(find.text('Pair with QR Code'));
      expect(qrPressed, isTrue);

      await tester.tap(find.text('User Guide'));
      expect(guidePressed, isTrue);
    },
  );

  testWidgets('EmptyStateView shows scanning state when isScanning is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: EmptyStateView(isScanning: true, onScanPressed: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Scanning Local Network...'), findsOneWidget);
    expect(find.text('Scanning Network...'), findsOneWidget);
  });
}
