import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockControlRepository extends Mock implements ControlRepository {}

void main() {
  late MockControlRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUpAll(() {
    registerFallbackValue(NavigationAction.back);
  });

  setUp(() {
    mockRepository = MockControlRepository();
    when(
      () => mockRepository.sendTap(
        testSerial,
        normalizedX: any(named: 'normalizedX'),
        normalizedY: any(named: 'normalizedY'),
      ),
    ).thenAnswer((_) async => true);
    when(() => mockRepository.sendNavigationAction(testSerial, any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.sendKeyEvent(testSerial, any()))
        .thenAnswer((_) async => true);
  });

  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 600,
            child: BlocProvider<ControlBloc>(
              create: (_) => ControlBloc(repository: mockRepository),
              child: const InputGestureViewportOverlay(
                deviceSerial: testSerial,
                child: ColoredBox(
                  key: Key('test_viewport_box'),
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'InputGestureViewportOverlay captures tap and dispatches normalized coordinates',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap in center of viewport
      await tester.tap(
        find.byKey(const Key('test_viewport_box')),
        warnIfMissed: false,
      );
      await tester.pump();

      verify(
        () => mockRepository.sendTap(
          testSerial,
          normalizedX: any(named: 'normalizedX'),
          normalizedY: any(named: 'normalizedY'),
        ),
      ).called(1);
    },
  );

  testWidgets('InputGestureViewportOverlay handles escape key as Back action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    verify(
      () => mockRepository.sendNavigationAction(
        testSerial,
        NavigationAction.back,
      ),
    ).called(1);
  });

  testWidgets('InputGestureViewportOverlay handles alphanumeric key presses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();

    verify(
      () => mockRepository.sendKeyEvent(testSerial, AndroidKeyCodes.keycodeA),
    ).called(1);
  });

  testWidgets('InputGestureViewportOverlay renders shortcut help badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('R-Click: Back  •  M-Click: Home'), findsOneWidget);
    expect(find.text('⌘K Text'), findsOneWidget);
  });
}
