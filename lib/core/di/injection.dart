import 'package:desk_droid/core/di/modules/apk_installer_di.dart';
import 'package:desk_droid/core/di/modules/audio_di.dart';
import 'package:desk_droid/core/di/modules/control_di.dart';
import 'package:desk_droid/core/di/modules/core_di.dart';
import 'package:desk_droid/core/di/modules/discovery_di.dart';
import 'package:desk_droid/core/di/modules/intent_dispatcher_di.dart';
import 'package:desk_droid/core/di/modules/logging_di.dart';
import 'package:desk_droid/core/di/modules/mcp_status_di.dart';
import 'package:desk_droid/core/di/modules/menubar_di.dart';
import 'package:desk_droid/core/di/modules/platform_di.dart';
import 'package:desk_droid/core/di/modules/productivity_di.dart';
import 'package:desk_droid/core/di/modules/streaming_di.dart';
import 'package:desk_droid/core/di/modules/updater_di.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Configures and registers all application dependencies across feature modules.
Future<void> initDependencies() async {
  // Platform first: core and feature modules depend on its contracts.
  registerPlatformDependencies(sl);
  registerCoreDependencies(sl);
  registerDiscoveryDependencies(sl);
  registerStreamingDependencies(sl);
  registerControlDependencies(sl);
  registerProductivityDependencies(sl);
  registerAudioDependencies(sl);
  registerLoggingDependencies(sl);
  registerApkInstallerDependencies(sl);
  registerIntentDispatcherDependencies(sl);
  registerMenuBarDependencies(sl);
  registerMcpStatusDependencies(sl);
  registerUpdaterDependencies(sl);
}
