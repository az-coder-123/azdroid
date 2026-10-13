import 'package:equatable/equatable.dart';

/// Connection medium between the Mac host and the Android target.
enum DeviceConnectionType { wireless, usb, dual }

/// Core domain entity representing an Android device.
class DeviceEntity extends Equatable {
  const DeviceEntity({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.connectionType,
    this.isConnected = false,
    this.isUnauthorized = false,
    this.requiresPairing = false,
    this.pairingPort,
    this.batteryLevel,
    this.model,
    this.usbSerial,
    this.wirelessSerial,
  });

  /// Unique hardware identifier or ADB serial.
  final String id;

  /// Convenience alias for [id] matching ADB serial convention.
  String get serial => id;

  /// User-friendly device name (e.g., "Google Pixel 8 Pro").
  final String name;

  /// Local IPv4 address for wireless connections.
  final String ipAddress;

  /// Wireless ADB communication port (default: 5555).
  final int port;

  /// Connection transport (USB, Wi-Fi, or Dual).
  final DeviceConnectionType connectionType;

  /// Active connection status.
  final bool isConnected;

  /// Whether the device is in unauthorized state (requires user to accept prompt on phone).
  final bool isUnauthorized;

  /// Whether this device was discovered via mDNS pairing service and needs PIN pairing.
  final bool requiresPairing;

  /// Optional mDNS pairing port (different from connect port).
  final int? pairingPort;

  /// Current battery percentage (0-100), if available.
  final int? batteryLevel;

  /// Device hardware model descriptor.
  final String? model;

  /// Hardware serial for USB connection if available.
  final String? usbSerial;

  /// Target descriptor (ip:port) for Wi-Fi connection if available.
  final String? wirelessSerial;

  /// Whether the device is concurrently connected via both USB and Wi-Fi.
  bool get isDualConnected => connectionType == DeviceConnectionType.dual;

  /// Returns a [DeviceEntity] configured for USB transport.
  DeviceEntity toUsbEndpoint() {
    return copyWith(
      id: usbSerial ?? id,
      connectionType: DeviceConnectionType.usb,
    );
  }

  /// Returns a [DeviceEntity] configured for Wireless transport.
  DeviceEntity toWirelessEndpoint() {
    return copyWith(
      id: wirelessSerial ?? id,
      connectionType: DeviceConnectionType.wireless,
    );
  }

  DeviceEntity copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceConnectionType? connectionType,
    bool? isConnected,
    bool? isUnauthorized,
    bool? requiresPairing,
    int? pairingPort,
    int? batteryLevel,
    String? model,
    String? usbSerial,
    String? wirelessSerial,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      requiresPairing: requiresPairing ?? this.requiresPairing,
      pairingPort: pairingPort ?? this.pairingPort,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      model: model ?? this.model,
      usbSerial: usbSerial ?? this.usbSerial,
      wirelessSerial: wirelessSerial ?? this.wirelessSerial,
    );
  }

  /// Whether this device is identified as a Xiaomi, Redmi, or POCO device.
  bool get isXiaomi {
    final lowerName = name.toLowerCase();
    final lowerModel = (model ?? '').toLowerCase();
    return lowerName.contains('xiaomi') ||
        lowerName.contains('redmi') ||
        lowerName.contains('poco') ||
        lowerModel.contains('xiaomi') ||
        lowerModel.contains('redmi') ||
        lowerModel.contains('poco');
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ipAddress,
    port,
    connectionType,
    isConnected,
    isUnauthorized,
    requiresPairing,
    pairingPort,
    batteryLevel,
    model,
    usbSerial,
    wirelessSerial,
  ];
}
