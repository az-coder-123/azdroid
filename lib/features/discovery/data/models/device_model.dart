import 'package:desk_droid/core/models/device_entity.dart';

/// Data transfer object extending [DeviceEntity] with serialization logic.
class DeviceModel extends DeviceEntity {
  const DeviceModel({
    required super.id,
    required super.name,
    required super.ipAddress,
    required super.port,
    required super.connectionType,
    super.isConnected = false,
    super.isUnauthorized = false,
    super.requiresPairing = false,
    super.pairingPort,
    super.batteryLevel,
    super.model,
    super.usbSerial,
    super.wirelessSerial,
  });

  /// Factory constructor to deserialize a [DeviceModel] from JSON.
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 5555,
      connectionType: (json['connectionType'] as String?) == 'dual'
          ? DeviceConnectionType.dual
          : (json['connectionType'] as String?) == 'usb'
          ? DeviceConnectionType.usb
          : DeviceConnectionType.wireless,
      isConnected: json['isConnected'] as bool? ?? false,
      isUnauthorized: json['isUnauthorized'] as bool? ?? false,
      requiresPairing: json['requiresPairing'] as bool? ?? false,
      pairingPort: json['pairingPort'] as int?,
      batteryLevel: json['batteryLevel'] as int?,
      model: json['model'] as String?,
      usbSerial: json['usbSerial'] as String?,
      wirelessSerial: json['wirelessSerial'] as String?,
    );
  }

  /// Converts this model instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'connectionType': connectionType == DeviceConnectionType.dual
          ? 'dual'
          : connectionType == DeviceConnectionType.usb
          ? 'usb'
          : 'wireless',
      'isConnected': isConnected,
      'isUnauthorized': isUnauthorized,
      'requiresPairing': requiresPairing,
      'pairingPort': pairingPort,
      'batteryLevel': batteryLevel,
      'model': model,
      'usbSerial': usbSerial,
      'wirelessSerial': wirelessSerial,
    };
  }

  /// Factory constructor to convert a domain [DeviceEntity] into a [DeviceModel].
  factory DeviceModel.fromEntity(DeviceEntity entity) {
    return DeviceModel(
      id: entity.id,
      name: entity.name,
      ipAddress: entity.ipAddress,
      port: entity.port,
      connectionType: entity.connectionType,
      isConnected: entity.isConnected,
      isUnauthorized: entity.isUnauthorized,
      requiresPairing: entity.requiresPairing,
      pairingPort: entity.pairingPort,
      batteryLevel: entity.batteryLevel,
      model: entity.model,
      usbSerial: entity.usbSerial,
      wirelessSerial: entity.wirelessSerial,
    );
  }
}
