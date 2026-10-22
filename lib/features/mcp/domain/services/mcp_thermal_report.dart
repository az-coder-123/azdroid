import 'package:desk_droid/core/extensions/line_split_extension.dart';

/// Summarizes `dumpsys thermalservice`: the throttling status and the
/// cached sensor temperatures (same format on Android 10 and 13, measured
/// 2026-10-22).
class McpThermalReport {
  const McpThermalReport._();

  /// `PowerManager.THERMAL_STATUS_*` names, by value.
  static const List<String> statusNames = [
    'none',
    'light',
    'moderate',
    'severe',
    'critical',
    'emergency',
    'shutdown',
  ];

  static final RegExp _status = RegExp(r'^Thermal Status:\s*(\d+)');
  static final RegExp _temperature = RegExp(
    r'Temperature\{mValue=([-\d.]+), mType=(-?\d+), mName=([^,]+),',
  );

  /// A readable report, or `null` when the output has no thermal status.
  static String? summarize(String output) {
    int? status;
    final sensors = <String, String>{};
    var inCached = false;
    for (final line in output.splitLines()) {
      final trimmed = line.trim();
      status ??= int.tryParse(_status.firstMatch(trimmed)?[1] ?? '');
      // Section headers: "Cached temperatures:", "Current temperatures
      // from HAL:".
      if (trimmed.contains('temperatures') && trimmed.endsWith(':')) {
        inCached = trimmed.startsWith('Cached');
        continue;
      }
      final t = _temperature.firstMatch(trimmed);
      // Prefer the cached readings; HAL readings repeat them.
      if (t != null && (inCached || !sensors.containsKey(t[3]))) {
        sensors[t[3]!] = '${t[1]} °C';
      }
    }
    if (status == null) return null;
    final name = status < statusNames.length ? statusNames[status] : '?';
    return [
      'Thermal status: $status ($name)${status >= 2 ? ': the system is '
                'throttling CPU/GPU, so frame rates drop' : ''}',
      for (final MapEntry(:key, :value) in sensors.entries) '• $key: $value',
    ].join('\n');
  }
}
