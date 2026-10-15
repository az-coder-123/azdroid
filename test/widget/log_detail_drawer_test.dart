import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_detail_drawer.dart';

void main() {
  group('LogDetailDrawer Widget Tests', () {
    final sampleTimestamp = DateTime(2026, 10, 15, 14, 30, 45, 123);

    Widget buildDrawer({required DeviceLogEntry entry, VoidCallback? onClose}) {
      return MaterialApp(
        home: Scaffold(
          body: LogDetailDrawer(entry: entry, onClose: onClose ?? () {}),
        ),
      );
    }

    testWidgets(
      'renders header with tag, PID:TID, and close button invokes onClose',
      (tester) async {
        bool closed = false;
        final entry = DeviceLogEntry(
          id: 1,
          timestamp: sampleTimestamp,
          pid: 7334,
          tid: 7350,
          level: LogLevel.error,
          tag: 'AndroidRuntime',
          message: 'FATAL EXCEPTION: main',
          rawLine: '10-15 14:30:45.123  7334  7350 E AndroidRuntime: FATAL EXCEPTION: main',
        );

        await tester.pumpWidget(
          buildDrawer(entry: entry, onClose: () => closed = true),
        );

        expect(find.text('AndroidRuntime'), findsOneWidget);
        expect(find.text('7334:7350'), findsOneWidget);
        expect(find.text('FATAL EXCEPTION: main'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );

    testWidgets('highlights stack trace lines and exceptions', (tester) async {
      const stackMessage =
          'java.lang.NullPointerException: Attempt to invoke virtual method on null object\n'
          '\tat com.example.app.MainActivity.onCreate(MainActivity.java:42)\n'
          '\tat android.app.Activity.performCreate(Activity.java:8000)';

      final entry = DeviceLogEntry(
        id: 2,
        timestamp: sampleTimestamp,
        pid: 1200,
        tid: 1200,
        level: LogLevel.error,
        tag: 'CrashHandler',
        message: stackMessage,
        rawLine: stackMessage,
      );

      await tester.pumpWidget(buildDrawer(entry: entry));

      expect(find.textContaining('NullPointerException'), findsOneWidget);
      expect(find.textContaining('MainActivity.onCreate'), findsOneWidget);
    });

    testWidgets(
      'shows JSON format toggle when payload is valid JSON and toggles formatting',
      (tester) async {
        const jsonMessage =
            '{"status":"ok","code":200,"users":["Alice","Bob"]}';

        final entry = DeviceLogEntry(
          id: 3,
          timestamp: sampleTimestamp,
          pid: 500,
          tid: 501,
          level: LogLevel.info,
          tag: 'NetworkResponse',
          message: jsonMessage,
          rawLine: jsonMessage,
        );

        await tester.pumpWidget(buildDrawer(entry: entry));

        expect(find.text('JSON: Raw'), findsOneWidget);

        await tester.tap(find.text('JSON: Raw'));
        await tester.pumpAndSettle();

        expect(find.text('JSON: Formatted'), findsOneWidget);
        expect(find.textContaining('"status": "ok"'), findsOneWidget);
      },
    );
  });
}
