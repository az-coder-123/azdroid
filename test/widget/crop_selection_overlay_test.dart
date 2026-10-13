import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/crop_selection_overlay.dart';

class MockScreenshotCubit extends Mock implements ScreenshotCubit {}

void main() {
  late MockScreenshotCubit mockCubit;
  const testSerial = '192.168.1.100:5555';

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
      ),
    ).thenAnswer((_) async {});
  });

  Widget createSubject() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 800,
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
      'drags to select bounding region and calls captureScreenshot on release',
      (tester) async {
        await tester.pumpWidget(createSubject());

        final gesture = await tester.startGesture(const Offset(220, 100));
        await gesture.moveTo(const Offset(320, 250));
        await tester.pump();

        // Dimension badge should appear
        expect(find.textContaining('100 × 150 px'), findsOneWidget);

        await gesture.up();
        await tester.pump();

        verify(
          () => mockCubit.captureScreenshot(
            testSerial,
            cropRectNormalized: any(named: 'cropRectNormalized'),
          ),
        ).called(1);
      },
    );
  });
}
