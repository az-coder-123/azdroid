import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/widgets/quick_text_input_dialog.dart';

class MockControlRepository extends Mock implements ControlRepository {}

void main() {
  late MockControlRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockControlRepository();
    when(() => mockRepository.sendText(testSerial, any()))
        .thenAnswer((_) async => true);
  });

  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<ControlBloc>(
          create: (_) => ControlBloc(repository: mockRepository),
          child: const QuickTextInputDialog(deviceSerial: testSerial),
        ),
      ),
    );
  }

  testWidgets(
    'QuickTextInputDialog renders input and injects text upon submission',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.text('Remote Text Injection'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Inject Text'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Xin chào Việt Nam');
      await tester.tap(find.text('Inject Text'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.sendText(testSerial, 'Xin chào Việt Nam'))
          .called(1);
    },
  );
}
