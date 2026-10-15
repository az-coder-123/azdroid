import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/clipboard_feedback_banner.dart';

class MockClipboardRepository extends Mock implements ClipboardRepository {}

void main() {
  late MockClipboardRepository mockRepository;

  setUp(() {
    mockRepository = MockClipboardRepository();
  });

  Widget createSubject(ClipboardCubit cubit) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<ClipboardCubit>.value(
          value: cubit,
          child: const ClipboardFeedbackBanner(),
        ),
      ),
    );
  }

  group('ClipboardFeedbackBanner Widget Tests', () {
    testWidgets('renders nothing when state is ClipboardInitial', (
      tester,
    ) async {
      final cubit = ClipboardCubit(repository: mockRepository);
      await tester.pumpWidget(createSubject(cubit));

      expect(find.byType(ClipboardFeedbackBanner), findsOneWidget);
      expect(find.byType(Container), findsNothing);

      await cubit.close();
    });

    testWidgets('renders syncing pill when sync is in progress', (
      tester,
    ) async {
      final completer = Completer<String?>();
      when(() => mockRepository.getHostClipboard())
          .thenAnswer((_) => completer.future);

      final cubit = ClipboardCubit(repository: mockRepository);
      await tester.pumpWidget(createSubject(cubit));

      // Trigger sync
      cubit.syncHostToDevice('192.168.1.1:5555');
      await tester.pump();

      expect(find.text('Syncing clipboard (Mac ➔ Android)...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete('');
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets(
      'renders synced pill with text snippet and resets on close button tap',
      (tester) async {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => 'Hello from Mac clipboard');
        when(
          () => mockRepository.setDeviceClipboard(
            '192.168.1.1:5555',
            'Hello from Mac clipboard',
          ),
        ).thenAnswer((_) async => true);

        final cubit = ClipboardCubit(
          repository: mockRepository,
          autoResetDuration: const Duration(seconds: 10),
        );
        await tester.pumpWidget(createSubject(cubit));

        await cubit.syncHostToDevice('192.168.1.1:5555');
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Clipboard synced (Mac ➔ Android): "Hello from Mac clipboard"',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Tap close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

        await cubit.close();
      },
    );

    testWidgets(
      'renders error pill when sync fails and dismisses on close tap',
      (tester) async {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => '');

        final cubit = ClipboardCubit(repository: mockRepository);
        await tester.pumpWidget(createSubject(cubit));

        await cubit.syncHostToDevice('192.168.1.1:5555');
        await tester.pumpAndSettle();

        expect(find.text('macOS clipboard is empty.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text('macOS clipboard is empty.'), findsNothing);

        await cubit.close();
      },
    );
  });
}
