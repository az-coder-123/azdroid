import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('WifiDeskApp renders DiscoveryPage with title and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WifiDeskApp());

    expect(find.text('WifiDesk'), findsOneWidget);
    expect(find.text('No Devices Discovered'), findsOneWidget);
    expect(find.text('Scan for Devices'), findsOneWidget);
  });
}
