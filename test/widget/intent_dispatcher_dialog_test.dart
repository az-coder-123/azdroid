import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_result_entity.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/repositories/intent_repository.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIntentRepository extends Mock implements IntentRepository {}

void main() {
  late MockIntentRepository mockRepo;
  const testSerial = '192.168.1.100:5555';

  setUpAll(() {
    registerFallbackValue(
      const IntentRequestEntity(dataUri: 'https://flutter.dev'),
    );
  });

  setUp(() {
    mockRepo = MockIntentRepository();
    when(() => mockRepo.dispatchIntent(any(), any())).thenAnswer(
      (_) async => const IntentResultEntity(
        success: true,
        message: 'Intent successfully dispatched.',
      ),
    );
  });

  Widget buildSubject({Size windowSize = const Size(800, 700)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: windowSize),
        child: Scaffold(
          body: BlocProvider<IntentDispatcherCubit>(
            create: (_) => IntentDispatcherCubit(repository: mockRepo),
            child: const IntentDispatcherDialog(deviceSerial: testSerial),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'IntentDispatcherDialog renders header, presets, inputs, and footer',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Deep Link & Intent Dispatcher'), findsOneWidget);
      expect(find.text('Device: $testSerial'), findsOneWidget);
      expect(find.text('Quick Preset Templates'), findsOneWidget);
      expect(find.text('HTTPS Web'), findsOneWidget);
      expect(find.text('Play Store'), findsOneWidget);
      expect(find.text('Dispatch Intent'), findsOneWidget);
    },
  );

  testWidgets('Selecting a preset updates the Data URI text field', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Play Store'));
    await tester.pumpAndSettle();

    final uriField = tester.widget<TextField>(
      find.widgetWithText(
        TextField,
        'market://details?id=com.google.android.youtube',
      ),
    );
    expect(
      uriField.controller?.text,
      equals('market://details?id=com.google.android.youtube'),
    );
  });

  testWidgets(
    'Submitting dispatch fires repository and displays success banner',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Dispatch Intent'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.dispatchIntent(testSerial, any())).called(1);
      expect(find.text('Intent successfully dispatched.'), findsOneWidget);
    },
  );

  testWidgets('Displays failure banner when repository returns error', (
    tester,
  ) async {
    when(() => mockRepo.dispatchIntent(any(), any())).thenAnswer(
      (_) async => const IntentResultEntity(
        success: false,
        message: 'Error: Activity not found',
      ),
    );

    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Dispatch Intent'));
    await tester.pumpAndSettle();

    expect(find.text('Error: Activity not found'), findsOneWidget);
  });

  testWidgets(
    'Renders gracefully in compact window dimensions without overflow',
    (tester) async {
      await tester.pumpWidget(buildSubject(windowSize: const Size(400, 480)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Deep Link & Intent Dispatcher'), findsOneWidget);
    },
  );
}
