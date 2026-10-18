import 'dart:convert';
import 'dart:io';

/// Text encoding of `adb` output on every host.
///
/// `adb` passes the device's bytes through unchanged, and Android emits
/// UTF-8. Decoding them with [systemEncoding] works on macOS (UTF-8) but
/// garbles non-ASCII text on Windows, whose system encoding is an ANSI code
/// page: "Cài đặt" became "CÃ i Ä‘áº·t". Malformed bytes (binary dumps) are
/// replaced instead of throwing.
const Encoding adbOutputEncoding = Utf8Codec(allowMalformed: true);

/// Encoding for the output of [executable]: [adbOutputEncoding] for adb,
/// [systemEncoding] for host tools such as `where`, `arp`, or `powershell`,
/// which print in the host's code page.
Encoding processOutputEncodingFor(String executable) {
  final name = executable.split(RegExp(r'[\\/]')).last.toLowerCase();
  return name == 'adb' || name == 'adb.exe'
      ? adbOutputEncoding
      : systemEncoding;
}
