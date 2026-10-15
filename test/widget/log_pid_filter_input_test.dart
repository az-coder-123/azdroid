import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_pid_filter_input.dart';

void main() {
  group('LogPidFilterInput Widget Tests', () {
    late TextEditingController controller;
    late Map<int, int> samplePidCounts;
    late Map<int, String> samplePidPrimaryTags;
    int? lastChangedPid;
    bool onChangedCalled = false;

    setUp(() {
      controller = TextEditingController();
      samplePidCounts = {7334: 142, 1052: 28, 550: 15};
      samplePidPrimaryTags = {
        7334: 'Finsky',
        1052: 'camerahalserver',
        550: 'ThermalInfo',
      };
      lastChangedPid = null;
      onChangedCalled = false;
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({String initialText = ''}) {
      if (initialText.isNotEmpty) {
        controller.text = initialText;
      }
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 250,
              height: 40,
              child: LogPidFilterInput(
                controller: controller,
                pidCounts: samplePidCounts,
                pidPrimaryTags: samplePidPrimaryTags,
                onChanged: (pid) {
                  onChangedCalled = true;
                  lastChangedPid = pid;
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders TextField and dropdown menu button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('PID'), findsOneWidget);
      expect(find.byType(PopupMenuButton<int>), findsOneWidget);
    });

    testWidgets(
      'typing numeric digits in textfield invokes onChanged with integer',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());

        await tester.enterText(find.byType(TextField), '7334');
        expect(onChangedCalled, isTrue);
        expect(lastChangedPid, equals(7334));
        expect(controller.text, equals('7334'));
      },
    );

    testWidgets(
      'typing invalid non-numeric text triggers onChanged with null',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());

        await tester.enterText(find.byType(TextField), 'abc');
        expect(onChangedCalled, isTrue);
        expect(lastChangedPid, isNull);
      },
    );

    testWidgets(
      'clear button appears when text is not empty and clears input on tap',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(initialText: '7334'));

        expect(find.byIcon(Icons.clear), findsOneWidget);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
        expect(lastChangedPid, isNull);
      },
    );

    testWidgets(
      'opening dropdown menu displays active PIDs with primary tags and counts',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Open the dropdown menu
        await tester.tap(find.byType(PopupMenuButton<int>));
        await tester.pumpAndSettle();

        // Verify menu entries
        expect(find.text('All PIDs / Reset'), findsOneWidget);
        expect(find.text('7334'), findsOneWidget);
        expect(find.text('Finsky'), findsOneWidget);
        expect(find.text('142'), findsOneWidget);

        expect(find.text('1052'), findsOneWidget);
        expect(find.text('camerahalserver'), findsOneWidget);
        expect(find.text('28'), findsOneWidget);

        // Select 1052
        await tester.tap(find.text('1052'));
        await tester.pumpAndSettle();

        expect(controller.text, equals('1052'));
        expect(lastChangedPid, equals(1052));
      },
    );

    testWidgets('selecting All PIDs / Reset clears the input', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialText: '550'));

      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All PIDs / Reset'));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(lastChangedPid, isNull);
    });
  });
}
