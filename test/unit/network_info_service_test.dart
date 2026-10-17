import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkInfoService', () {
    test(
      'NetworkInfoServiceImpl returns a string or null gracefully',
      () async {
        final service = NetworkInfoServiceImpl();
        final ip = await service.getLocalIpAddress();

        // In real macOS runtime with Wi-Fi, it returns IPv4 address; in test runner it can be string or null
        if (ip != null) {
          expect(ip, isNotEmpty);
          expect(ip.contains('.'), isTrue);
        } else {
          expect(ip, isNull);
        }
      },
    );
  });
}
