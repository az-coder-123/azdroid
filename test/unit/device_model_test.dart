import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_desk/features/discovery/data/models/device_model.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

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
  });
}
