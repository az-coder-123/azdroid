import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/streaming/domain/errors/stream_start_exception.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/stream_start_failure_message.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_status_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const device = DeviceEntity(
    id: '192.168.1.3:5555',
    name: 'Redmi M2004J19C',
    ipAddress: '192.168.1.3',
    port: 5555,
    connectionType: DeviceConnectionType.wireless,
  );
  final message = StreamStartFailure.deviceUnauthorized.messageFor(device.name);

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MirroringErrorFallback(device: device, message: message),
        ),
      ),
    );
  }

  testWidgets('shows the unauthorized guidance and both actions', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(800, 600));

    expect(find.text(message), findsOneWidget);
    expect(find.text('Back to Devices'), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });

  testWidgets('does not overflow in a small window', (tester) async {
    await pumpAtSize(tester, const Size(280, 240));

    expect(tester.takeException(), isNull);
    expect(find.text('Retry Connection'), findsOneWidget);
  });
}
