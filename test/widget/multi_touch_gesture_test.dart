import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ControlRepository {}

void main() {
  const serial = '192.168.1.3:5555';
  late _MockRepository repository;
  late List<(TouchStreamPhase, List<NormalizedPoint>)> streamed;

  setUpAll(() => registerFallbackValue(TouchStreamPhase.start));

  setUp(() {
    repository = _MockRepository();
    streamed = [];
    when(() => repository.sendTouchStream(any(), any(), any()))
        .thenAnswer((invocation) async {
          streamed.add((
            invocation.positionalArguments[1] as TouchStreamPhase,
            invocation.positionalArguments[2] as List<NormalizedPoint>,
          ));
          return true;
        });
    // Alt itself is forwarded as a key press, as any mapped key is.
    when(() => repository.sendKeyEvent(any(), any()))
        .thenAnswer((_) async => true);
  });

  Future<Rect> pumpOverlay(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 600,
              child: BlocProvider<ControlBloc>(
                create: (_) => ControlBloc(repository: repository),
                child: const InputGestureViewportOverlay(
                  deviceSerial: serial,
                  showShortcutBadge: false,
                  child: ColoredBox(key: Key('viewport'), color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getRect(find.byType(InputGestureViewportOverlay));
  }

  testWidgets('trackpad pan is a live one-finger drag (it used to be lost)', (
    tester,
  ) async {
    final box = await pumpOverlay(tester);
    final trackpad = TestPointer(1, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(trackpad.panZoomStart(box.center));
    await tester.sendEventToBinding(
      trackpad.panZoomUpdate(box.center, pan: const Offset(0, -60)),
    );
    await tester.sendEventToBinding(trackpad.panZoomEnd());
    await tester.pump();

    expect(streamed.map((e) => e.$1), [
      TouchStreamPhase.start,
      TouchStreamPhase.move,
      TouchStreamPhase.end,
    ]);
    expect(streamed.first.$2.single, const NormalizedPoint(0.5, 0.5));
    expect(streamed[1].$2.single, const NormalizedPoint(0.5, 0.4));
    verifyNever(
      () => repository.sendScroll(
        any(),
        normalizedX: any(named: 'normalizedX'),
        normalizedY: any(named: 'normalizedY'),
        deltaX: any(named: 'deltaX'),
        deltaY: any(named: 'deltaY'),
      ),
    );
  });

  testWidgets('trackpad pinch sends two fingers that spread with the scale', (
    tester,
  ) async {
    final box = await pumpOverlay(tester);
    final trackpad = TestPointer(2, PointerDeviceKind.trackpad);
    await tester.sendEventToBinding(trackpad.panZoomStart(box.center));
    await tester.sendEventToBinding(
      trackpad.panZoomUpdate(box.center, scale: 1.2),
    );
    await tester.sendEventToBinding(
      trackpad.panZoomUpdate(box.center, scale: 2),
    );
    await tester.sendEventToBinding(trackpad.panZoomEnd());
    await tester.pump();

    expect(streamed.map((e) => e.$2.length), everyElement(2));
    double spread(List<NormalizedPoint> f) => (f[0].x - f[1].x).abs();
    expect(spread(streamed[1].$2), greaterThan(spread(streamed[0].$2)));
    expect(streamed.last.$1, TouchStreamPhase.end);
  });

  testWidgets('Alt + drag pinches around the center instead of swiping', (
    tester,
  ) async {
    final box = await pumpOverlay(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    final mouse = await tester.startGesture(
      box.topLeft + const Offset(75, 150),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveTo(box.topLeft + const Offset(30, 60));
    await mouse.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    expect(streamed.first.$2, const [
      NormalizedPoint(0.25, 0.25),
      NormalizedPoint(0.75, 0.75),
    ]);
    expect(streamed.last.$1, TouchStreamPhase.end);
    verifyNever(
      () => repository.sendSwipe(
        any(),
        startX: any(named: 'startX'),
        startY: any(named: 'startY'),
        endX: any(named: 'endX'),
        endY: any(named: 'endY'),
        durationMs: any(named: 'durationMs'),
      ),
    );
  });
}
