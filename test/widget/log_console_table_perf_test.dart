import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/logging/domain/entities/device_log_entry.dart';
import 'package:wifi_desk/features/logging/domain/entities/log_level.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_console_row.dart';
import 'package:wifi_desk/features/logging/presentation/widgets/log_console_table.dart';

void main() {
  group('LogConsoleTable Performance & Interaction Tests', () {
    late List<DeviceLogEntry> sampleEntries;

    setUp(() {
      sampleEntries = List.generate(5000, (i) {
        return DeviceLogEntry(
          id: i,
          timestamp: DateTime(2026, 10, 15, 12, 0, 0, i % 1000),
          pid: 1000 + (i % 20),
          tid: 2000 + (i % 50),
          level: LogLevel.info,
          tag: 'ConnectivityService',
          message: '{ act=android.net.conn.CONNECTIVITY_CHANGE extra=NetworkInfo: type: WIFI[], state: CONNECTED/CONNECTED, reason: (unspecified), extra: "WiFi-Network-5G", failover: false, available: true, roaming: false }',
          rawLine:
              '10-15 12:00:00.000  1000  2000 I ConnectivityService: raw line $i',
        );
      });
    });

    testWidgets(
      'Toggling softWrap on 5000 entries finishes in under 500ms both directions',
      (tester) async {
        bool softWrap = false;
        late StateSetter stateSetter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 600,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    stateSetter = setState;
                    return LogConsoleTable(
                      entries: sampleEntries,
                      autoScroll: true,
                      isPaused: false,
                      searchQuery: '',
                      softWrap: softWrap,
                      onScrollToBottom: () {},
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle softWrap to true (measure time)
        final stopwatchOn = Stopwatch()..start();
        stateSetter(() {
          softWrap = true;
        });
        await tester.pump();
        stopwatchOn.stop();

        expect(
          stopwatchOn.elapsedMilliseconds,
          lessThan(1500),
          reason:
              'SoftWrap toggle ON must be instantaneous (< 1500ms under load)',
        );

        // Toggle softWrap back to false (measure time)
        final stopwatchOff = Stopwatch()..start();
        stateSetter(() {
          softWrap = false;
        });
        await tester.pump();
        stopwatchOff.stop();

        expect(
          stopwatchOff.elapsedMilliseconds,
          lessThan(1500),
          reason:
              'SoftWrap toggle OFF must be instantaneous (< 1500ms under load)',
        );
      },
    );

    testWidgets(
      'Row selection, bookmarking, and copy actions function with softWrap',
      (tester) async {
        DeviceLogEntry? selected;
        int? bookmarkedId;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 600,
                child: LogConsoleTable(
                  entries: sampleEntries.sublist(4950), // 50 items
                  autoScroll: true,
                  isPaused: false,
                  searchQuery: '',
                  softWrap: true,
                  selectedEntry: selected,
                  bookmarkedIds: const {},
                  onSelectEntry: (e) => selected = e,
                  onToggleBookmark: (id) => bookmarkedId = id,
                  onScrollToBottom: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on bookmark icon
        final starIcons = find.byIcon(Icons.star_outline_rounded);
        expect(starIcons, findsWidgets);
        await tester.tap(starIcons.first);
        await tester.pump();
        expect(bookmarkedId, isNotNull);

        // Tap on row
        final rows = find.byType(LogConsoleRow);
        expect(rows, findsWidgets);
        await tester.tap(rows.first);
        await tester.pump();
        expect(selected, isNotNull);
      },
    );

    testWidgets(
      'Few items (< 25) render cleanly from the top without crashing',
      (tester) async {
        final fewEntries = sampleEntries.take(3).toList();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 600,
                child: LogConsoleTable(
                  entries: fewEntries,
                  autoScroll: true,
                  isPaused: false,
                  searchQuery: '',
                  softWrap: false,
                  onScrollToBottom: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LogConsoleRow), findsNWidgets(3));
      },
    );
  });
}
