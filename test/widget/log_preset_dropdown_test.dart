import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_criteria.dart';
import 'package:desk_droid/features/logging/domain/entities/log_filter_preset.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_preset_dropdown.dart';

void main() {
  group('LogPresetDropdown Widget Tests', () {
    testWidgets(
      'renders Presets button and opens menu displaying preset options',
      (tester) async {
        LogFilterPreset? selectedPreset;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: LogPresetDropdown(
                  currentFilter: const LogFilterCriteria(),
                  onPresetSelected: (preset) => selectedPreset = preset,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Presets'), findsOneWidget);

        // Open menu
        await tester.tap(find.text('Presets'));
        await tester.pumpAndSettle();

        expect(find.text('All Logs'), findsOneWidget);
        expect(find.text('Crashes & ANRs'), findsOneWidget);
        expect(find.text('Network & HTTP'), findsOneWidget);
        expect(find.text('Starred Only'), findsOneWidget);

        // Select 'Crashes & ANRs'
        await tester.tap(find.text('Crashes & ANRs'));
        await tester.pumpAndSettle();

        expect(selectedPreset, isNotNull);
        expect(selectedPreset!.id, equals('crash_hunter'));
        expect(selectedPreset!.criteria.isRegex, isTrue);
      },
    );
  });
}
