import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/clipboard_sync_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClipboardRepository extends Mock implements ClipboardRepository {}

void main() {
  late MockClipboardRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockClipboardRepository();
    when(() => mockRepository.getHostClipboard())
        .thenAnswer((_) async => 'Text to sync');
    when(() => mockRepository.setDeviceClipboard(testSerial, any()))
        .thenAnswer((_) async => true);
  });

  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<ClipboardCubit>(
          create: (_) => ClipboardCubit(repository: mockRepository),
          child: const ClipboardSyncMenuButton(deviceSerial: testSerial),
        ),
      ),
    );
  }

  testWidgets(
    'ClipboardSyncMenuButton renders icon and opens menu options on tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ClipboardSyncMenuButton), findsOneWidget);
      expect(find.byIcon(Icons.content_paste_go_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.content_paste_go_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Push Mac ➔ Android'), findsOneWidget);
      expect(find.text('Pull Android ➔ Mac'), findsOneWidget);
      expect(find.text('Auto-Sync (Active)'), findsOneWidget);
    },
  );
}
