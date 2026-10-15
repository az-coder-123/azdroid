import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_tag_filter_input.dart';

void main() {
  group('LogTagFilterInput Widget Tests', () {
    late TextEditingController controller;
    late Map<String, int> sampleTagCounts;
    String? lastChangedTag;

    setUp(() {
      controller = TextEditingController();
      sampleTagCounts = {
        'Finsky': 142,
        'camerahalserver': 28,
        'ThermalInfo': 15,
      };
      lastChangedTag = null;
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
              child: LogTagFilterInput(
                controller: controller,
                tagCounts: sampleTagCounts,
                onChanged: (tag) => lastChangedTag = tag,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders TextField and dropdown menu button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tag (e.g. Activity)'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('typing in textfield invokes onChanged', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byType(TextField), 'Flutter');
      expect(lastChangedTag, equals('Flutter'));
      expect(controller.text, equals('Flutter'));
    });

    testWidgets(
      'clear button appears when text is not empty and clears input on tap',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(initialText: 'Finsky'));

        expect(find.byIcon(Icons.clear), findsOneWidget);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
        expect(lastChangedTag, equals(''));
      },
    );

    testWidgets(
      'opening dropdown menu displays modules with line counts and selecting tag works',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Open the dropdown menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Verify menu entries
        expect(find.text('All Tags / Reset'), findsOneWidget);
        expect(find.text('Finsky'), findsOneWidget);
        expect(find.text('142'), findsOneWidget);
        expect(find.text('camerahalserver'), findsOneWidget);
        expect(find.text('28'), findsOneWidget);
        expect(find.text('ThermalInfo'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);

        // Select 'camerahalserver'
        await tester.tap(find.text('camerahalserver'));
        await tester.pumpAndSettle();

        expect(controller.text, equals('camerahalserver'));
        expect(lastChangedTag, equals('camerahalserver'));
      },
    );

    testWidgets('selecting All Tags resets the input', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialText: 'ThermalInfo'));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All Tags / Reset'));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(lastChangedTag, equals(''));
    });
  });
}
