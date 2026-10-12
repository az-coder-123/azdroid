/// Represents a raw device entry parsed from `adb devices -l`.
class AdbDevice {
  const AdbDevice({
    required this.serial,
    required this.state,
    this.product,
    this.model,
    this.device,
    this.transportId,
  });

  final String serial;
  final String state;
  final String? product;
  final String? model;
  final String? device;
  final String? transportId;

  bool get isUsb => !serial.contains(':');
  bool get isAuthorized => state == 'device';
  bool get isUnauthorized => state == 'unauthorized';
}
