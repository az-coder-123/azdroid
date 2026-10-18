import 'dart:io';

/// Checks scrcpy's SET_DISPLAY_POWER the way DeskDroid's Screen Off uses
/// it: the panel turns off while the device stays awake and video keeps
/// flowing, and the server's restore process turns it on when it exits.
class DisplayPowerProbe {
  DisplayPowerProbe({required this.adb, required this.serial});

  final String adb;
  final String serial;

  static const Duration _settle = Duration(milliseconds: 1500);
  static const Duration _restoreLimit = Duration(seconds: 5);
  static const Duration _pollInterval = Duration(milliseconds: 250);

  /// `dumpsys SurfaceFlinger` power modes meaning "panel off": numeric on
  /// older Android (Android 10: `powerMode=0`), named on newer (`Off`).
  static const Set<String> _offModes = {'0', 'Off'};

  bool? offWhileAwake;
  int? videoBytesWhileOff;
  bool? restoredOnExit;

  /// Sends "off" with [sendOff], then checks the panel, wakefulness, and
  /// that [videoBytes] keeps growing while the screen content changes.
  Future<void> checkOff({
    required Future<void> Function() sendOff,
    required int Function() videoBytes,
  }) async {
    await sendOff();
    await Future<void>.delayed(_settle);
    final before = videoBytes();
    // Change what is on screen so the encoder has frames to send.
    await _shell('am start -a android.settings.SETTINGS');
    await Future<void>.delayed(_settle);
    videoBytesWhileOff = videoBytes() - before;
    offWhileAwake = await isPanelOff() && await _isAwake();
  }

  /// Call after the server was stopped; polls until the panel is on again.
  Future<void> checkRestoredOnExit() async {
    final stopwatch = Stopwatch()..start();
    var off = await isPanelOff();
    while (off && stopwatch.elapsed < _restoreLimit) {
      await Future<void>.delayed(_pollInterval);
      off = await isPanelOff();
    }
    restoredOnExit = !off;
  }

  bool get isOk =>
      offWhileAwake == true &&
      (videoBytesWhileOff ?? 0) > 0 &&
      restoredOnExit == true;

  String describe() =>
      'screen off: panel off while awake=$offWhileAwake, '
      'video bytes while off=$videoBytesWhileOff, '
      'panel on after server exit=$restoredOnExit';

  /// Whether any display SurfaceFlinger lists is powered off. The built-in
  /// panel is not always listed first (Redmi 9: second of two entries).
  Future<bool> isPanelOff() async {
    final out = await _shell('dumpsys SurfaceFlinger');
    return RegExp(r'powerMode=(\w+)')
        .allMatches(out)
        .any((m) => _offModes.contains(m.group(1)));
  }

  Future<bool> _isAwake() async =>
      (await _shell('dumpsys power')).contains('mWakefulness=Awake');

  Future<String> _shell(String command) async {
    final r = await Process.run(adb, ['-s', serial, 'shell', command]);
    return '${r.stdout}';
  }
}
