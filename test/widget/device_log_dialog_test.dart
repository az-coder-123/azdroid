import 'dart:async';

import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/logging/domain/entities/device_log_entry.dart';
import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:desk_droid/features/logging/domain/repositories/device_log_repository.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:desk_droid/features/logging/presentation/widgets/device_log_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceLogRepository extends Mock implements DeviceLogRepository {}

void main() {
  late MockDeviceLogRepository mockRepo;
  late StreamController<List<DeviceLogEntry>> streamController;
  const testSerial = '192.168.1.3:5555';

  setUp(() {
    mockRepo = MockDeviceLogRepository();
    streamController = StreamController<List<DeviceLogEntry>>.broadcast();

    when(() => mockRepo.streamLogs(testSerial))
        .thenAnswer((_) => streamController.stream);
    when(() => mockRepo.recordingStatus)
        .thenReturn(LogFileRecordingStatus.idle());
  });

  tearDown(() async {
    await streamController.close();
  });

  Widget buildSubject({required DeviceLogCubit cubit}) {
    return RepositoryProvider<ShortcutScheme>.value(
      value: ShortcutScheme.mac,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => BlocProvider<DeviceLogCubit>.value(
                      value: cubit..startLogging(testSerial),
                      child: const DeviceLogDialog(deviceSerial: testSerial),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('Close button pops the dialog successfully', (tester) async {
    final cubit = DeviceLogCubit(repository: mockRepo);

    await tester.pumpWidget(buildSubject(cubit: cubit));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Device Logcat Console'), findsOneWidget);
    expect(find.text(testSerial), findsOneWidget);

    final closeBtn = find.byKey(
      const ValueKey('device_log_dialog_close_button'),
    );
    expect(closeBtn, findsOneWidget);

    // Tap close button
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Verify dialog was popped and is no longer present
    expect(find.text('Device Logcat Console'), findsNothing);
    await cubit.close();
  });

  testWidgets('Close button functions during active streaming log ingestion', (
    tester,
  ) async {
    final cubit = DeviceLogCubit(repository: mockRepo);

    await tester.pumpWidget(buildSubject(cubit: cubit));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Emit batches simulating live logcat stream
    streamController.add([
      DeviceLogEntry(
        id: 1,
        timestamp: DateTime.now(),
        pid: 1001,
        tid: 1001,
        level: LogLevel.info,
        tag: 'ActivityManager',
        message: 'Starting activity',
        rawLine:
            '10-22 20:00:00.000 1001 1001 I ActivityManager: Starting activity',
      ),
    ]);
    await tester.pump();

    streamController.add([
      DeviceLogEntry(
        id: 2,
        timestamp: DateTime.now(),
        pid: 1002,
        tid: 1002,
        level: LogLevel.debug,
        tag: 'WifiService',
        message: 'RSSI changed',
        rawLine: '10-22 20:00:01.000 1002 1002 D WifiService: RSSI changed',
      ),
    ]);
    await tester.pump();

    final closeBtn = find.byKey(
      const ValueKey('device_log_dialog_close_button'),
    );
    expect(closeBtn, findsOneWidget);

    // Verify tapping close button pops dialog cleanly even while stream is active
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.text('Device Logcat Console'), findsNothing);
    await cubit.close();
  });

  testWidgets('Escape key closes the dialog when no focus or drawer is open', (
    tester,
  ) async {
    final cubit = DeviceLogCubit(repository: mockRepo);

    await tester.pumpWidget(buildSubject(cubit: cubit));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Device Logcat Console'), findsOneWidget);

    // Press Escape
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Verify dialog was closed
    expect(find.text('Device Logcat Console'), findsNothing);
    await cubit.close();
  });
}
