import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/discovery/data/models/device_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceModel', () {
    const testModel = DeviceModel(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
      isConnected: false,
      batteryLevel: 85,
      model: 'Pixel 8',
    );

    test('should correctly deserialize from JSON', () {
      final jsonMap = {
        'id': '192.168.1.100:5555',
        'name': 'Google Pixel 8',
        'ipAddress': '192.168.1.100',
        'port': 5555,
        'connectionType': 'wireless',
        'isConnected': false,
        'batteryLevel': 85,
        'model': 'Pixel 8',
      };

      final result = DeviceModel.fromJson(jsonMap);

      expect(result, equals(testModel));
      expect(result.connectionType, equals(DeviceConnectionType.wireless));
    });

    test('should correctly serialize to JSON', () {
      final jsonMap = testModel.toJson();

      expect(jsonMap['id'], equals('192.168.1.100:5555'));
      expect(jsonMap['name'], equals('Google Pixel 8'));
      expect(jsonMap['ipAddress'], equals('192.168.1.100'));
      expect(jsonMap['port'], equals(5555));
      expect(jsonMap['connectionType'], equals('wireless'));
      expect(jsonMap['isConnected'], isFalse);
      expect(jsonMap['batteryLevel'], equals(85));
    });

    test('should correctly instantiate from DeviceEntity', () {
      const entity = DeviceEntity(
        id: 'usb-1234',
        name: 'Samsung Galaxy S24',
        ipAddress: '127.0.0.1',
        port: 5555,
        connectionType: DeviceConnectionType.usb,
      );

      final model = DeviceModel.fromEntity(entity);

      expect(model.id, equals(entity.id));
      expect(model.name, equals(entity.name));
      expect(model.connectionType, equals(DeviceConnectionType.usb));
    });

    test('should correctly serialize and deserialize dual mode device', () {
      const dualEntity = DeviceEntity(
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

      final model = DeviceModel.fromEntity(dualEntity);
      expect(model.isDualConnected, isTrue);
      expect(model.usbSerial, equals('9789f2350404'));
      expect(model.wirelessSerial, equals('192.168.1.3:5555'));

      final json = model.toJson();
      expect(json['connectionType'], equals('dual'));
      expect(json['usbSerial'], equals('9789f2350404'));
      expect(json['wirelessSerial'], equals('192.168.1.3:5555'));

      final deserialized = DeviceModel.fromJson(json);
      expect(deserialized.isDualConnected, isTrue);
      expect(deserialized.usbSerial, equals('9789f2350404'));
      expect(deserialized.wirelessSerial, equals('192.168.1.3:5555'));

      final usbEndpoint = deserialized.toUsbEndpoint();
      expect(usbEndpoint.id, equals('9789f2350404'));
      expect(usbEndpoint.connectionType, equals(DeviceConnectionType.usb));

      final wirelessEndpoint = deserialized.toWirelessEndpoint();
      expect(wirelessEndpoint.id, equals('192.168.1.3:5555'));
      expect(
        wirelessEndpoint.connectionType,
        equals(DeviceConnectionType.wireless),
      );
    });
  });
}
