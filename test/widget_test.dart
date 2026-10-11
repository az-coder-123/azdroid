import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/main.dart';

void main() {
  testWidgets('WifiDesk initial smoke test', (WidgetTester tester) async {
    // Build the WifiDesk application and trigger a frame.
    await tester.pumpWidget(const WifiDeskApp());

    // Verify that the title and scan button are rendered.
    expect(find.text('WifiDesk'), findsOneWidget);
    expect(find.text('Scan for Devices'), findsOneWidget);
  });
}
