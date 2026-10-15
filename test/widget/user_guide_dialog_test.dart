import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/guide/presentation/widgets/components/guide_command_snippet.dart';
import 'package:desk_droid/features/guide/presentation/widgets/user_guide_dialog.dart';

void main() {
  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: UserGuideDialog()),
    );
  }

  testWidgets(
    'UserGuideDialog renders header, sidebar categories, and initial Quick Start section',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('DeskDroid User Guide'), findsOneWidget);
      expect(
        find.text(
          'Complete handbook for wireless mirroring & remote control on macOS',
        ),
        findsOneWidget,
      );

      // Sidebar categories verification
      expect(find.text('Quick Start & Pairing'), findsOneWidget);
      expect(find.text('Xiaomi / MIUI Setup'), findsOneWidget);
      expect(find.text('Mouse & Shortcuts'), findsOneWidget);
      expect(find.text('Files & Clipboard'), findsOneWidget);
      expect(find.text('Troubleshooting FAQ'), findsOneWidget);

      // Initial section: Quick Start
      expect(find.text('Quick Start & 3 Connection Modes'), findsOneWidget);
      expect(
        find.text('Method 1: 1-Click USB to Wi-Fi Switch (Easiest)'),
        findsOneWidget,
      );
      expect(find.text('Method 2: 6-Digit Wi-Fi Pairing Code'), findsOneWidget);
    },
  );

  testWidgets('UserGuideDialog switches tabs and shows Xiaomi setup section', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Tap Xiaomi sidebar item
    await tester.tap(find.text('Xiaomi / MIUI Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Xiaomi / MIUI / HyperOS Setup'), findsOneWidget);
    expect(
      find.text('Critical: Enable "Security Settings" for Mouse Control'),
      findsOneWidget,
    );
    expect(
      find.text('Toggle ON: USB debugging (Security settings).'),
      findsOneWidget,
    );
  });

  testWidgets(
    'UserGuideDialog switches to Controls, Productivity, and Troubleshooting tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Controls tab
      await tester.tap(find.text('Mouse & Shortcuts'));
      await tester.pumpAndSettle();
      expect(find.text('Mouse & Keyboard Gestures'), findsOneWidget);
      expect(find.text('macOS Keyboard Navigation'), findsOneWidget);
      expect(find.text('Go to Home Screen'), findsOneWidget);

      // Productivity tab
      await tester.tap(find.text('Files & Clipboard'));
      await tester.pumpAndSettle();
      expect(
        find.text('Productivity: Files, Clipboard & Audio'),
        findsOneWidget,
      );
      expect(
        find.text('Drag & Drop Transfers & APK Sideloading'),
        findsOneWidget,
      );

      // Troubleshooting tab
      await tester.tap(find.text('Troubleshooting FAQ'));
      await tester.pumpAndSettle();
      expect(find.text('Troubleshooting & Common Fixes'), findsOneWidget);
      expect(
        find.text('1. "No route to host" or cannot connect via Wi-Fi'),
        findsOneWidget,
      );
    },
  );

  testWidgets('GuideCommandSnippet copies command and displays Copied state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: GuideCommandSnippet(command: 'adb tcpip 5555')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('adb tcpip 5555'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);

    // Tap Copy button
    await tester.tap(find.text('Copy'));
    await tester.pump();

    expect(find.text('Copied'), findsOneWidget);

    // Let 2-second timer expire
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copy'), findsOneWidget);
  });
}
