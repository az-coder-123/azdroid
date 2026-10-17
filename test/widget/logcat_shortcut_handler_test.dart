import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/features/logging/presentation/widgets/logcat_shortcut_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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

    Widget createSubject({
      bool hasSelectedEntry = false,
      ShortcutScheme scheme = ShortcutScheme.mac,
    }) {
      return RepositoryProvider<ShortcutScheme>.value(
        value: scheme,
        child: MaterialApp(
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
        ),
      );
    }

    // Same expectations for every platform scheme: the primary modifier
    // triggers the action, the other platform's modifier does not.
    final schemes = {
      'macOS': (
        ShortcutScheme.mac,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.control,
      ),
      'Windows': (
        ShortcutScheme.pc,
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.meta,
      ),
    };

    Future<void> press(
      WidgetTester tester,
      LogicalKeyboardKey modifier,
      LogicalKeyboardKey key,
    ) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
    }

    for (final MapEntry(key: os, value: (scheme, primary, other))
        in schemes.entries) {
      testWidgets('$os: primary+F focuses search, other modifier does not', (
        tester,
      ) async {
        await tester.pumpWidget(createSubject(scheme: scheme));

        await press(tester, other, LogicalKeyboardKey.keyF);
        expect(searchFocusNode.hasFocus, isFalse);

        await press(tester, primary, LogicalKeyboardKey.keyF);
        expect(searchFocusNode.hasFocus, isTrue);
      });

      testWidgets('$os: primary+K clears the console', (tester) async {
        await tester.pumpWidget(createSubject(scheme: scheme));

        await press(tester, other, LogicalKeyboardKey.keyK);
        await press(tester, primary, LogicalKeyboardKey.keyK);

        expect(clearCount, 1);
      });

      testWidgets('$os: primary+Down scrolls to bottom', (tester) async {
        await tester.pumpWidget(createSubject(scheme: scheme));

        await press(tester, primary, LogicalKeyboardKey.arrowDown);

        expect(scrollCount, 1);
      });
    }

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
