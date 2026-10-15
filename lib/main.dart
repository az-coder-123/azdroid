import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desk_droid/core/constants/app_constants.dart';
import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/pages/discovery_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator and dependency injection container
  await initDependencies();

  runApp(const DeskDroidApp());
}

/// Root application widget for DeskDroid.
class DeskDroidApp extends StatelessWidget {
  const DeskDroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DiscoveryCubit>(create: (_) => sl<DiscoveryCubit>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DiscoveryPage(),
      ),
    );
  }
}
