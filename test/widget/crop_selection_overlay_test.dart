import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/productivity/domain/entities/screenshot_destination.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/crop_selection_overlay.dart';

class MockScreenshotCubit extends Mock implements ScreenshotCubit {}

void main() {
  late MockScreenshotCubit mockCubit;
  const testSerial = '192.168.1.100:5555';

  setUpAll(() {
    registerFallbackValue(ScreenshotDestination.both);
  });

  setUp(() {
    mockCubit = MockScreenshotCubit();
    when(() => mockCubit.state)
        .thenReturn(const ScreenshotSelectingArea(testSerial));
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCubit.cancelAreaSelection()).thenReturn(null);
    when(
      () => mockCubit.captureScreenshot(
        any(),
        cropRectNormalized: any(named: 'cropRectNormalized'),
        customSaveDirectory: any(named: 'customSaveDirectory'),
        destination: any(named: 'destination'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget createSubject() {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 400,
            child: BlocProvider<ScreenshotCubit>.value(
              value: mockCubit,
              child: const CropSelectionOverlay(deviceSerial: testSerial),
            ),
          ),
        ),
      ),
    );
  }

  group('CropSelectionOverlay', () {
    testWidgets('renders instruction helper banner and close button', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());

      expect(find.textContaining('Drag to select area'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('cancels area selection when close icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      verify(() => mockCubit.cancelAreaSelection()).called(1);
    });

    testWidgets(
      'drags to select region, shows destination toolbar, and captures to clipboard',
      (tester) async {
        await tester.pumpWidget(createSubject());

        final gesture = await tester.startGesture(const Offset(50, 50));
        await gesture.moveTo(const Offset(150, 200));
        await tester.pump();

        // Dimension badge should appear
        expect(find.textContaining('100 × 150 px'), findsOneWidget);

        await gesture.up();
        await tester.pump();

        // Toolbar options appear
        expect(find.text('Clipboard'), findsOneWidget);
        expect(find.text('Save File'), findsOneWidget);
        expect(find.text('Both'), findsOneWidget);

        // Tap Clipboard option
        await tester.tap(find.text('Clipboard'));
        await tester.pump();

        verify(
          () => mockCubit.captureScreenshot(
            testSerial,
            cropRectNormalized: any(named: 'cropRectNormalized'),
            destination: ScreenshotDestination.clipboard,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'allows modifying selection by dragging handle after initial marquee',
      (tester) async {
        await tester.pumpWidget(createSubject());

        // 1. Initial drag: from (50, 50) to (150, 150) -> 100x100
        final gesture1 = await tester.startGesture(const Offset(50, 50));
        await gesture1.moveTo(const Offset(150, 150));
        await tester.pump();
        await gesture1.up();
        await tester.pump();

        expect(find.text('Clipboard'), findsOneWidget);

        // 2. Drag bottom-right handle at (150, 150) to (200, 200) -> 150x150
        final gesture2 = await tester.startGesture(const Offset(150, 150));
        await gesture2.moveTo(const Offset(200, 200));
        await tester.pump();
        await gesture2.up();
        await tester.pump();

        // 3. Confirm with Save File
        await tester.tap(find.text('Save File'));
        await tester.pump();

        verify(
          () => mockCubit.captureScreenshot(
            testSerial,
            cropRectNormalized: any(
              named: 'cropRectNormalized',
              that: isA<Rect>().having(
                (r) => r.right,
                'right',
                closeTo(200 / 400, 0.01),
              ),
            ),
            destination: ScreenshotDestination.file,
          ),
        ).called(1);
      },
    );
  });
}
