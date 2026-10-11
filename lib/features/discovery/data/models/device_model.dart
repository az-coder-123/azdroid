import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';

/// Data transfer object extending [DeviceEntity] with serialization logic.
class DeviceModel extends DeviceEntity {
  const DeviceModel({
    required super.id,
    required super.name,
    required super.ipAddress,
    required super.port,
    required super.connectionType,
    super.isConnected = false,
    super.batteryLevel,
    super.model,
  });

  /// Factory constructor to deserialize a [DeviceModel] from JSON.
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 5555,
      connectionType: (json['connectionType'] as String?) == 'usb'
          ? DeviceConnectionType.usb
          : DeviceConnectionType.wireless,
      isConnected: json['isConnected'] as bool? ?? false,
      batteryLevel: json['batteryLevel'] as int?,
      model: json['model'] as String?,
    );
  }

  /// Converts this model instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'connectionType':
          connectionType == DeviceConnectionType.usb ? 'usb' : 'wireless',
      'isConnected': isConnected,
      'batteryLevel': batteryLevel,
      'model': model,
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
      batteryLevel: entity.batteryLevel,
      model: entity.model,
    );
  }
}
