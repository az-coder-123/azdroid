import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/menubar/presentation/widgets/menu_bar_companion_popover.dart';

void main() {
  Widget createSubject(MenuBarCubit cubit) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: BlocProvider<MenuBarCubit>.value(
            value: cubit,
            child: const MenuBarCompanionPopover(),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'MenuBarCompanionPopover renders brand, idle status, and window toggle',
    (WidgetTester tester) async {
      final cubit = MenuBarCubit();
      await tester.pumpWidget(createSubject(cubit));
      await tester.pumpAndSettle();

      expect(find.text('DeskDroid Companion'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);
      expect(find.text('Hide Mirroring Window'), findsOneWidget);

      await tester.tap(find.text('Hide Mirroring Window'));
      await tester.pumpAndSettle();

      expect(find.text('Show Mirroring Window'), findsOneWidget);
      cubit.close();
    },
  );

  testWidgets(
    'MenuBarCompanionPopover renders active device card when mirroring',
    (WidgetTester tester) async {
      final cubit = MenuBarCubit();
      cubit.updateActiveSession(
        deviceName: 'Google Pixel 8',
        batteryLevel: 92,
        latencyMs: 14,
        fps: 60,
      );

      await tester.pumpWidget(createSubject(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Mirroring'), findsOneWidget);
      expect(find.text('Google Pixel 8'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('14ms'), findsOneWidget);
      expect(find.text('60 FPS'), findsOneWidget);

      cubit.close();
    },
  );

  testWidgets(
    'MenuBarCompanionPopover renders and triggers onOpenGuide action',
    (WidgetTester tester) async {
      final cubit = MenuBarCubit();
      var guideOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: BlocProvider<MenuBarCubit>.value(
                value: cubit,
                child: MenuBarCompanionPopover(
                  onOpenGuide: () => guideOpened = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User Guide & Shortcuts'), findsOneWidget);
      await tester.tap(find.text('User Guide & Shortcuts'));
      await tester.pumpAndSettle();

      expect(guideOpened, isTrue);
      cubit.close();
    },
  );
}
