import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';
import 'package:desk_droid/features/discovery/presentation/widgets/device_card.dart';

void main() {
  const dualDevice = DeviceEntity(
    id: '192.168.1.3:5555',
    name: 'M2004J19C',
    ipAddress: '192.168.1.3',
    port: 5555,
    connectionType: DeviceConnectionType.dual,
    isConnected: true,
    model: 'M2004J19C',
    usbSerial: '9789f2350404',
    wirelessSerial: '192.168.1.3:5555',
  );

  Widget buildTestWidget({
    required DeviceEntity device,
    ValueChanged<DeviceEntity>? onMirror,
    ValueChanged<String>? onDisconnect,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DeviceCard(
          device: device,
          onConnect: (_) {},
          onDisconnect: onDisconnect ?? (_) {},
          onMirror: onMirror,
        ),
      ),
    );
  }

  testWidgets('renders dual mode badge and formatted subtitle', (tester) async {
    await tester.pumpWidget(buildTestWidget(device: dualDevice));

    expect(find.text('M2004J19C'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Dual Mode'), findsOneWidget);
    expect(
      find.text('USB (9789f2350404) • Wi-Fi (192.168.1.3:5555)'),
      findsOneWidget,
    );
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('USB'), findsOneWidget);
    expect(find.text('Mirror'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });

  testWidgets('mirrors via Wi-Fi by default in dual mode', (tester) async {
    DeviceEntity? mirroredTarget;

    await tester.pumpWidget(
      buildTestWidget(
        device: dualDevice,
        onMirror: (target) => mirroredTarget = target,
      ),
    );

    await tester.tap(find.text('Mirror'));
    await tester.pump();

    expect(mirroredTarget, isNotNull);
    expect(
      mirroredTarget!.connectionType,
      equals(DeviceConnectionType.wireless),
    );
    expect(mirroredTarget!.id, equals('192.168.1.3:5555'));
  });

  testWidgets('switches to USB transport and mirrors via USB', (tester) async {
    DeviceEntity? mirroredTarget;

    await tester.pumpWidget(
      buildTestWidget(
        device: dualDevice,
        onMirror: (target) => mirroredTarget = target,
      ),
    );

    await tester.tap(find.text('USB'));
    await tester.pump();

    await tester.tap(find.text('Mirror'));
    await tester.pump();

    expect(mirroredTarget, isNotNull);
    expect(mirroredTarget!.connectionType, equals(DeviceConnectionType.usb));
    expect(mirroredTarget!.id, equals('9789f2350404'));
  });

  testWidgets('disconnects wireless serial in dual mode', (tester) async {
    String? disconnectedId;

    await tester.pumpWidget(
      buildTestWidget(
        device: dualDevice,
        onDisconnect: (id) => disconnectedId = id,
      ),
    );

    await tester.tap(find.text('Disconnect'));
    await tester.pump();

    expect(disconnectedId, equals('192.168.1.3:5555'));
  });
}
