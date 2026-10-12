/// Represents an mDNS service entry discovered via `adb mdns services`.
class AdbMdnsService {
  const AdbMdnsService({
    required this.serviceName,
    required this.serviceType,
    required this.ipAddress,
    required this.port,
  });

  final String serviceName;
  final String serviceType;
  final String ipAddress;
  final int port;

  bool get isPairingService => serviceType.contains('_adb-tls-pairing');
  bool get isConnectService =>
      serviceType.contains('_adb-tls-connect') ||
      serviceType.contains('_adb._tcp');
}
