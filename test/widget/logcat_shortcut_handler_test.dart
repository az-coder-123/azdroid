import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/logcat_shortcut_handler.dart';

void main() {
  group('LogcatShortcutHandler Widget Tests', () {
    late FocusNode searchFocusNode;
    late TextEditingController textController;
    var clearCount = 0;
    var pauseCount = 0;
    var scrollCount = 0;
    var closeDetailCount = 0;
    var closeDialogCount = 0;

    setUp(() {
      searchFocusNode = FocusNode();
      textController = TextEditingController();
      clearCount = 0;
      pauseCount = 0;
      scrollCount = 0;
      closeDetailCount = 0;
      closeDialogCount = 0;
    });

    tearDown(() {
      searchFocusNode.dispose();
      textController.dispose();
    });

    Widget createSubject({bool hasSelectedEntry = false}) {
      return MaterialApp(
        home: Scaffold(
          body: LogcatShortcutHandler(
            searchFocusNode: searchFocusNode,
            hasSelectedEntry: hasSelectedEntry,
            onClearConsole: () => clearCount++,
            onTogglePause: () => pauseCount++,
            onScrollToBottom: () => scrollCount++,
            onCloseDetail: () => closeDetailCount++,
            onCloseDialog: () => closeDialogCount++,
            child: Column(
              children: [
                TextField(
                  key: const Key('search_input'),
                  focusNode: searchFocusNode,
                  controller: textController,
                ),
                const SizedBox(height: 20),
                const Text('Console Content'),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('Cmd+F focuses search input field', (tester) async {
      await tester.pumpWidget(createSubject());
      expect(searchFocusNode.hasFocus, isFalse);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();

      expect(searchFocusNode.hasFocus, isTrue);
    });

    testWidgets('Ctrl+F focuses search input field', (tester) async {
      await tester.pumpWidget(createSubject());
      expect(searchFocusNode.hasFocus, isFalse);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(searchFocusNode.hasFocus, isTrue);
    });

    testWidgets('Cmd+K / Ctrl+K invokes onClearConsole', (tester) async {
      await tester.pumpWidget(createSubject());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();

      expect(clearCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(clearCount, 2);
    });

    testWidgets('Cmd+Down / Ctrl+Down invokes onScrollToBottom', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();

      expect(scrollCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(scrollCount, 2);
    });

    testWidgets('Space toggles pause when text field is NOT focused', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      expect(searchFocusNode.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(pauseCount, 1);
    });

    testWidgets('Space is inhibited when user is typing in TextField', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());

      // Focus text field
      await tester.tap(find.byKey(const Key('search_input')));
      await tester.pump();
      expect(searchFocusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(pauseCount, 0);
    });

    testWidgets('Esc unfocuses search input if focused', (tester) async {
      await tester.pumpWidget(createSubject(hasSelectedEntry: true));

      await tester.tap(find.byKey(const Key('search_input')));
      await tester.pump();
      expect(searchFocusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(searchFocusNode.hasFocus, isFalse);
      expect(closeDetailCount, 0);
      expect(closeDialogCount, 0);
    });

    testWidgets('Esc closes detail drawer if entry is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(hasSelectedEntry: true));
      expect(searchFocusNode.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closeDetailCount, 1);
      expect(closeDialogCount, 0);
    });

    testWidgets(
      'Esc closes dialog when no entry is selected and search is unfocused',
      (tester) async {
        await tester.pumpWidget(createSubject(hasSelectedEntry: false));
        expect(searchFocusNode.hasFocus, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(closeDetailCount, 0);
        expect(closeDialogCount, 1);
      },
    );
  });
}
