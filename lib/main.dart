import 'package:desk_droid/core/constants/app_constants.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/pages/discovery_page.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_device_activity_banner.dart';
import 'package:desk_droid/features/mcp_status/presentation/widgets/mcp_status_indicator.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/pages/mirroring_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator and dependency injection container
  await initDependencies();

  runApp(const DeskDroidApp());
}

/// Root application widget for DeskDroid.
///
/// Acts as the composition root that wires feature-to-feature navigation.
class DeskDroidApp extends StatelessWidget {
  const DeskDroidApp({super.key});

  static Route<void> _mirroringRoute(DeviceEntity device) =>
      MaterialPageRoute<void>(
        builder: (_) => MirroringPage(
          device: device,
          deviceStatusBanner: McpDeviceActivityBanner(
            deviceSerial: device.serial,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider<ShortcutScheme>.value(value: sl<ShortcutScheme>()),
        BlocProvider<DiscoveryCubit>(create: (_) => sl<DiscoveryCubit>()),
        // Provided above MaterialApp so dialogs pushed on the root navigator
        // can read host details as well.
        BlocProvider<HostContextCubit>(
          create: (_) => sl<HostContextCubit>()..load(),
        ),
        // App-wide, so the toolbar indicator and its panel share one check.
        BlocProvider<McpStatusCubit>(
          create: (_) => sl<McpStatusCubit>()..load(),
        ),
        // App-wide singleton owned by the service locator, so do not close it.
        BlocProvider<MenuBarCubit>.value(value: sl<MenuBarCubit>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DiscoveryPage(
          mirroringRouteBuilder: _mirroringRoute,
          statusActions: [McpStatusIndicator()],
        ),
      ),
    );
  }
}
