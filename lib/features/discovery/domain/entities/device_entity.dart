import 'package:equatable/equatable.dart';

/// Connection medium between the Mac host and the Android target.
enum DeviceConnectionType {
  wireless,
  usb,
}

/// Core domain entity representing an Android device.
class DeviceEntity extends Equatable {
  const DeviceEntity({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.connectionType,
    this.isConnected = false,
    this.batteryLevel,
    this.model,
  });

  /// Unique hardware identifier or ADB serial.
  final String id;

  /// User-friendly device name (e.g., "Google Pixel 8 Pro").
  final String name;

  /// Local IPv4 address for wireless connections.
  final String ipAddress;

  /// Wireless ADB communication port (default: 5555).
  final int port;

  /// Connection transport (USB or Wi-Fi).
  final DeviceConnectionType connectionType;

  /// Active connection status.
  final bool isConnected;

  /// Current battery percentage (0-100), if available.
  final int? batteryLevel;

  /// Device hardware model descriptor.
  final String? model;

  DeviceEntity copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceConnectionType? connectionType,
    bool? isConnected,
    int? batteryLevel,
    String? model,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      model: model ?? this.model,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        ipAddress,
        port,
        connectionType,
        isConnected,
        batteryLevel,
        model,
      ];
}
