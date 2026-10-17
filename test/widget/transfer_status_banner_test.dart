import 'dart:async';

import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_local_file_system_gateway.dart';

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

void main() {
  late MockFileTransferRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockFileTransferRepository();
  });

  Widget createSubject(FileTransferCubit cubit) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BlocProvider<FileTransferCubit>.value(
          value: cubit,
          child: const TransferStatusBanner(),
        ),
      ),
    );
  }

  testWidgets(
    'TransferStatusBanner displays progress when transfer is active',
    (WidgetTester tester) async {
      final completer = Completer<bool>();
      when(() => mockRepository.pushFile(testSerial, '/Users/mac/photo.png'))
          .thenAnswer((_) => completer.future);

      final cubit = FileTransferCubit(
        repository: mockRepository,
        fileSystem: const FakeLocalFileSystemGateway(),
      );
      await tester.pumpWidget(createSubject(cubit));

      // Initial: nothing visible
      expect(find.byType(TransferStatusBanner), findsOneWidget);
      expect(find.text('Transferring: photo.png'), findsNothing);

      // Trigger transfer
      unawaited(cubit.transferFiles(testSerial, ['/Users/mac/photo.png']));
      await tester.pump();

      // In active state
      expect(find.text('Transferring: photo.png'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Complete transfer
      completer.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('File Transfer Complete'), findsOneWidget);

      await cubit.close();
    },
  );

  testWidgets(
    'TransferStatusBanner displays failure and dismisses on close button',
    (WidgetTester tester) async {
      when(() => mockRepository.pushFile(testSerial, '/Users/mac/fail.txt'))
          .thenAnswer((_) async => false);

      final cubit = FileTransferCubit(
        repository: mockRepository,
        fileSystem: const FakeLocalFileSystemGateway(),
      );
      await tester.pumpWidget(createSubject(cubit));

      unawaited(cubit.transferFiles(testSerial, ['/Users/mac/fail.txt']));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Failed'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Failed'), findsNothing);

      await cubit.close();
    },
  );
}
