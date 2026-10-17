import 'package:desk_droid/core/extensions/line_split_extension.dart';
import 'package:desk_droid/core/models/adb_device.dart';
import 'package:desk_droid/core/models/adb_mdns_service.dart';

/// Pure parser responsible for converting stdout lines from ADB CLI commands into typed models.
class AdbOutputParser {
  const AdbOutputParser();

  /// Parses the stdout text from `adb devices -l`.
  List<AdbDevice> parseDevices(String stdout) {
    final devices = <AdbDevice>[];
    final lines = stdout.splitLines();

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('List of devices attached')) {
        continue;
      }

      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.length < 2) continue;

      final serial = tokens[0];
      final state = tokens[1];

      String? product;
      String? model;
      String? device;
      String? transportId;

      for (int i = 2; i < tokens.length; i++) {
        final pair = tokens[i];
        if (pair.startsWith('product:')) {
          product = pair.substring(8);
        } else if (pair.startsWith('model:')) {
          model = pair.substring(6).replaceAll('_', ' ');
        } else if (pair.startsWith('device:')) {
          device = pair.substring(7);
        } else if (pair.startsWith('transport_id:')) {
          transportId = pair.substring(13);
        }
      }

      devices.add(
        AdbDevice(
          serial: serial,
          state: state,
          product: product,
          model: model,
          device: device,
          transportId: transportId,
        ),
      );
    }

    return devices;
  }

  /// Parses stdout output from `adb mdns services`.
  List<AdbMdnsService> parseMdnsServices(String stdout) {
    final services = <AdbMdnsService>[];
    final lines = stdout.splitLines();

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('List of discovered mdns services')) {
        continue;
      }

      // Format can be:
      // <name>\t<regType>\t<ip>:<port> OR <name>.<regType> <ip>:<port>
      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.length >= 2) {
        String serviceName = tokens[0];
        String serviceType = '';
        String endpoint = tokens.last;

        if (tokens.length >= 3) {
          serviceType = tokens[1];
          endpoint = tokens[2];
        } else {
          // Tokens: [name._type, endpoint]
          if (serviceName.contains('._adb-tls-connect')) {
            serviceType = '_adb-tls-connect._tcp';
            serviceName = serviceName.split('._adb-tls-connect').first;
          } else if (serviceName.contains('._adb-tls-pairing')) {
            serviceType = '_adb-tls-pairing._tcp';
            serviceName = serviceName.split('._adb-tls-pairing').first;
          } else if (serviceName.contains('._adb.')) {
            serviceType = '_adb._tcp';
            serviceName = serviceName.split('._adb.').first;
          }
        }

        final endpointParts = endpoint.split(':');
        if (endpointParts.length == 2) {
          final ip = endpointParts[0].trim();
          final port = int.tryParse(endpointParts[1].trim());
          if (port != null && ip.isNotEmpty) {
            services.add(
              AdbMdnsService(
                serviceName: serviceName,
                serviceType: serviceType,
                ipAddress: ip,
                port: port,
              ),
            );
          }
        }
      }
    }

    return services;
  }
}
