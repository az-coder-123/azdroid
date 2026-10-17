import 'dart:io';

import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

void main() {
  late MockFileTransferRepository mockRepository;
  const testSerial = '192.168.1.50:5555';

  setUp(() {
    mockRepository = MockFileTransferRepository();
  });

  Widget createSubject({
    required FileTransferCubit cubit,
    required Widget child,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<FileTransferCubit>.value(
          value: cubit,
          child: FileDropTargetOverlay(deviceSerial: testSerial, child: child),
        ),
      ),
    );
  }

  testWidgets(
    'FileDropTargetOverlay renders child when idle without dragging overlay',
    (WidgetTester tester) async {
      final cubit = FileTransferCubit(repository: mockRepository);
      await tester.pumpWidget(
        createSubject(cubit: cubit, child: const Text('Viewport Content')),
      );

      expect(find.text('Viewport Content'), findsOneWidget);
      expect(find.text('Drop Files to Transfer'), findsNothing);

      await cubit.close();
    },
  );

  testWidgets(
    'FileDropTargetOverlay shows and hides visual feedback on drag enter and exit',
    (WidgetTester tester) async {
      final cubit = FileTransferCubit(repository: mockRepository);
      await tester.pumpWidget(
        createSubject(cubit: cubit, child: const Text('Viewport Content')),
      );

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
      final eventDetails = DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      );

      // Simulate dragging entered
      dropTarget.onDragEntered?.call(eventDetails);
      await tester.pump();

      expect(find.text('Drop Files to Transfer'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);

      // Simulate dragging exited
      dropTarget.onDragExited?.call(eventDetails);
      await tester.pump();

      expect(find.text('Drop Files to Transfer'), findsNothing);

      await cubit.close();
    },
  );

  testWidgets(
    'FileDropTargetOverlay resolves dropped files and initiates transfer',
    (WidgetTester tester) async {
      final tempDir = Directory.systemTemp.createTempSync('drop_test_');
      final testFile = File('${tempDir.path}/photo.png')
        ..writeAsStringSync('dummy content');

      when(() => mockRepository.pushFile(testSerial, testFile.path))
          .thenAnswer((_) async => true);

      final cubit = FileTransferCubit(repository: mockRepository);
      await tester.pumpWidget(
        createSubject(cubit: cubit, child: const Text('Viewport Content')),
      );

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // Simulate drop done
      dropTarget.onDragDone?.call(
        DropDoneDetails(
          files: [DropItemFile(testFile.path)],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );

      await tester.pumpAndSettle();

      verify(() => mockRepository.pushFile(testSerial, testFile.path))
          .called(1);

      tempDir.deleteSync(recursive: true);
      await cubit.close();
    },
  );

  testWidgets(
    'FileDropTargetOverlay expands directory recursively when a folder is dropped',
    (WidgetTester tester) async {
      final tempDir = Directory.systemTemp.createTempSync('drop_dir_test_');
      // Use host separators: directory listings return them on every OS.
      final nestedDir = Directory(p.join(tempDir.path, 'nested'))..createSync();
      final file1 = File(p.join(tempDir.path, 'doc1.txt'))
        ..writeAsStringSync('1');
      final file2 = File(p.join(nestedDir.path, 'doc2.pdf'))
        ..writeAsStringSync('2');

      when(() => mockRepository.pushFile(testSerial, any()))
          .thenAnswer((_) async => true);

      final cubit = FileTransferCubit(repository: mockRepository);
      await tester.pumpWidget(
        createSubject(cubit: cubit, child: const Text('Viewport Content')),
      );

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // Simulate dropping a directory
      dropTarget.onDragDone?.call(
        DropDoneDetails(
          files: [DropItemDirectory(tempDir.path, const [])],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );

      await tester.pumpAndSettle();

      verify(() => mockRepository.pushFile(testSerial, file1.path)).called(1);
      verify(() => mockRepository.pushFile(testSerial, file2.path)).called(1);

      tempDir.deleteSync(recursive: true);
      await cubit.close();
    },
  );

  testWidgets(
    'FileDropTargetOverlay directly initiates APK install when an apk is dropped',
    (WidgetTester tester) async {
      final tempDir = Directory.systemTemp.createTempSync('drop_apk_test_');
      final apkFile = File('${tempDir.path}/app-release.apk')
        ..writeAsStringSync('apk data');

      when(() => mockRepository.installApk(testSerial, apkFile.path))
          .thenAnswer((_) async => true);

      final cubit = FileTransferCubit(repository: mockRepository);
      await tester.pumpWidget(
        createSubject(cubit: cubit, child: const Text('Viewport Content')),
      );

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // Simulate dropping an APK
      dropTarget.onDragDone?.call(
        DropDoneDetails(
          files: [DropItemFile(apkFile.path)],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );

      await tester.pumpAndSettle();

      verify(() => mockRepository.installApk(testSerial, apkFile.path))
          .called(1);
      verifyNever(() => mockRepository.pushFile(any(), any()));

      tempDir.deleteSync(recursive: true);
      await cubit.close();
    },
  );
}
