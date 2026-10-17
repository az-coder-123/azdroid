import 'package:desk_droid/core/extensions/line_split_extension.dart';

/// Extracts neighbor IPv4 addresses from `arp` output on any desktop OS.
///
/// Works on both formats without branching on the OS:
/// - macOS / Linux `arp -an`: `? (192.168.1.3) at 7c:fd:... on en0`
/// - Windows `arp -a`: `  192.168.1.3   7c-fd-6b-f6-70-49   dynamic`
class ArpTableParser {
  const ArpTableParser();

  static final RegExp _ipv4 = RegExp(
    r'(?<![\d.])(\d{1,3}(?:\.\d{1,3}){3})(?![\d.])',
  );

  /// Line fragments that mark headers or entries without a live neighbor.
  static const List<String> _skipMarkers = [
    '(incomplete)', // macOS / Linux unresolved entry
    'Interface:', // Windows per-adapter header (contains the host IP)
    'invalid', // Windows unresolved entry
  ];

  /// Returns IPs in `<subnetPrefix>.x`, excluding network and broadcast.
  List<String> parse(String output, String subnetPrefix) {
    final ips = <String>[];
    for (final line in output.splitLines()) {
      if (_skipMarkers.any(line.contains)) continue;
      final ip = _ipv4.firstMatch(line)?.group(1);
      if (ip == null || !ip.startsWith('$subnetPrefix.')) continue;
      if (ip.endsWith('.255') || ip.endsWith('.0')) continue;
      ips.add(ip);
    }
    return ips;
  }
}
