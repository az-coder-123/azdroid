import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';
import 'package:desk_droid/features/updater/domain/entities/semantic_version.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_state.dart';
import 'package:desk_droid/features/updater/presentation/widgets/update_badge_indicator.dart';
import 'package:desk_droid/features/updater/presentation/widgets/update_banner.dart';
import 'package:desk_droid/features/updater/presentation/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdaterCubit extends MockCubit<UpdaterState>
    implements UpdaterCubit {}

void main() {
  late MockUpdaterCubit mockCubit;

  const sampleInfo = AppUpdateInfo(
    currentVersion: SemanticVersion(1, 4, 0),
    latestVersion: SemanticVersion(1, 4, 1),
    tagName: 'v1.4.1',
    releaseName: 'Azdroid 1.4.1 — Faster Mirroring',
    releaseNotes: 'Fixed high CPU usage and improved latency.',
    htmlUrl: 'https://github.com/az-coder-123/azdroid/releases/tag/v1.4.1',
    downloadUrl: 'https://example.com/Azdroid-v1.4.1-macOS.zip',
    assetName: 'Azdroid-v1.4.1-macOS.zip',
    assetSizeBytes: 42 * 1024 * 1024,
  );

  setUp(() {
    mockCubit = MockUpdaterCubit();
  });

  Widget wrapWithScaffold(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<UpdaterCubit>.value(value: mockCubit, child: child),
      ),
    );
  }

  group('Update UI Widgets', () {
    testWidgets('UpdateBadgeIndicator shows badge when update is available', (
      tester,
    ) async {
      when(() => mockCubit.state)
          .thenReturn(const UpdaterAvailable(updateInfo: sampleInfo));

      await tester.pumpWidget(wrapWithScaffold(const UpdateBadgeIndicator()));
      await tester.pump();

      expect(find.byType(Badge), findsOneWidget);
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
    });

    testWidgets('UpdateBanner displays and triggers dismiss callback', (
      tester,
    ) async {
      when(() => mockCubit.state)
          .thenReturn(const UpdaterAvailable(updateInfo: sampleInfo));

      await tester.pumpWidget(wrapWithScaffold(const UpdateBanner()));
      await tester.pump();

      expect(find.text('Azdroid v1.4.1 is available!'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      final dismissButton = find.byTooltip('Dismiss');
      expect(dismissButton, findsOneWidget);

      await tester.tap(dismissButton);
      verify(() => mockCubit.dismissBanner()).called(1);
    });

    testWidgets(
      'UpdateDialog renders version pills and release notes cleanly',
      (tester) async {
        when(() => mockCubit.state)
            .thenReturn(const UpdaterAvailable(updateInfo: sampleInfo));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<UpdaterCubit>.value(
              value: mockCubit,
              child: const UpdateDialog(info: sampleInfo),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Software Update Available'), findsOneWidget);
        expect(find.text('v1.4.1 (Latest)'), findsOneWidget);
        expect(find.text('Azdroid-v1.4.1-macOS.zip'), findsOneWidget);
        expect(
          find.text('Fixed high CPU usage and improved latency.'),
          findsOneWidget,
        );
        expect(find.text('Download Update'), findsOneWidget);
        expect(find.text('View on GitHub'), findsOneWidget);
      },
    );
  });
}
