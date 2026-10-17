import 'package:desk_droid/features/discovery/data/parsers/arp_table_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ArpTableParser();
  const expected = ['192.168.1.1', '192.168.1.3'];

  // The same neighbor table rendered by each OS; results must be identical.
  const outputs = {
    'macOS arp -an': '''
? (192.168.1.1) at cc:71:90:12:2a:40 on en0 ifscope [ethernet]
? (192.168.1.3) at 7c:fd:6b:f6:70:49 on en0 ifscope [ethernet]
? (192.168.1.6) at (incomplete) on en0 ifscope [ethernet]
? (192.168.1.255) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]
? (192.168.2.55) at 11:22:33:44:55:66 on en0 ifscope [ethernet]
? (224.0.0.251) at 1:0:5e:0:0:fb on en0 ifscope permanent [ethernet]
''',
    'Windows arp -a':
        '\r\n'
        'Interface: 192.168.1.10 --- 0x5\r\n'
        '  Internet Address      Physical Address      Type\r\n'
        '  192.168.1.1           cc-71-90-12-2a-40     dynamic\r\n'
        '  192.168.1.3           7c-fd-6b-f6-70-49     dynamic\r\n'
        '  192.168.1.6           00-00-00-00-00-00     invalid\r\n'
        '  192.168.1.255         ff-ff-ff-ff-ff-ff     static\r\n'
        '  224.0.0.251           01-00-5e-00-00-fb     static\r\n'
        '\r\n'
        'Interface: 192.168.2.20 --- 0x9\r\n'
        '  192.168.2.55          11-22-33-44-55-66     dynamic\r\n',
  };

  for (final entry in outputs.entries) {
    test('parses ${entry.key} output', () {
      expect(parser.parse(entry.value, '192.168.1'), expected);
    });
  }

  test('does not match a prefix inside a longer address', () {
    expect(parser.parse('? (10.192.168.1.5) at x', '192.168.1'), isEmpty);
  });
}
