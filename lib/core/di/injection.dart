import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/di/modules/apk_installer_di.dart';
import 'package:wifi_desk/core/di/modules/audio_di.dart';
import 'package:wifi_desk/core/di/modules/control_di.dart';
import 'package:wifi_desk/core/di/modules/core_di.dart';
import 'package:wifi_desk/core/di/modules/discovery_di.dart';
import 'package:wifi_desk/core/di/modules/logging_di.dart';
import 'package:wifi_desk/core/di/modules/menubar_di.dart';
import 'package:wifi_desk/core/di/modules/productivity_di.dart';
import 'package:wifi_desk/core/di/modules/streaming_di.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Configures and registers all application dependencies across feature modules.
Future<void> initDependencies() async {
  registerCoreDependencies(sl);
  registerDiscoveryDependencies(sl);
  registerStreamingDependencies(sl);
  registerControlDependencies(sl);
  registerProductivityDependencies(sl);
  registerAudioDependencies(sl);
  registerLoggingDependencies(sl);
  registerApkInstallerDependencies(sl);
  registerMenuBarDependencies(sl);
}
