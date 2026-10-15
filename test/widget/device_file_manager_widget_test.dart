import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_list_view.dart';

void main() {
  const file1 = RemoteFileEntity(
    name: 'vacation.png',
    path: '/sdcard/Download/vacation.png',
    sizeBytes: 1024 * 1024 * 5,
    isDirectory: false,
    modifiedDate: '2026-08-10 14:00',
  );

  const dir1 = RemoteFileEntity(
    name: 'Music',
    path: '/sdcard/Download/Music',
    sizeBytes: 0,
    isDirectory: true,
  );

  Widget createSubject(DeviceFileManagerState state) {
    return MaterialApp(
      home: Scaffold(
        body: DeviceFileListView(
          state: state,
          deviceSerial: '192.168.1.3:5555',
          onOpenFolder: (_) {},
          onToggleSelection: (_) {},
          onRetry: () {},
        ),
      ),
    );
  }

  testWidgets('DeviceFileListView renders directories and regular files', (
    tester,
  ) async {
    const state = DeviceFileManagerLoaded(
      currentDirectory: '/sdcard/Download/',
      files: [dir1, file1],
      selectedFiles: {},
    );

    await tester.pumpWidget(createSubject(state));
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('vacation.png'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets(
    'DeviceFileListView shows search empty state when no files match query',
    (tester) async {
      const state = DeviceFileManagerLoaded(
        currentDirectory: '/sdcard/Download/',
        files: [file1],
        searchQuery: 'nonexistent',
      );

      await tester.pumpWidget(createSubject(state));
      await tester.pumpAndSettle();

      expect(find.text('No files matching "nonexistent"'), findsOneWidget);
    },
  );
}
