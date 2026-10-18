import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_process_tools.dart';
import 'package:desk_droid/core/platform/mcp_client_locations.dart';
import 'package:desk_droid/core/services/mcp_activity_paths.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_activity_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_binary_inspector.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_client_config_reader.dart';
import 'package:desk_droid/features/mcp_status/data/datasources/mcp_process_lister.dart';
import 'package:desk_droid/features/mcp_status/data/repositories/mcp_status_repository_impl.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers the MCP server status check (executable, AI client
/// configurations, running sessions, live activity) and its app-wide cubit.
void registerMcpStatusDependencies(GetIt sl) {
  sl.registerLazySingleton<McpStatusRepository>(() {
    final os = sl<HostOs>();
    final paths = sl<HostPaths>();
    final tools = sl<HostProcessTools>();
    final executableName = os.executableName(
      McpStatusConstants.executableBaseName,
    );
    final executable = paths.context.join(
      paths.executableDirectory,
      executableName,
    );
    return McpStatusRepositoryImpl(
      binaryInspector: McpBinaryInspector(
        executablePath: executable,
        processExecutor: sl<ProcessExecutor>(),
        tools: tools,
      ),
      configReader: McpClientConfigReader(
        expectedExecutable: executable,
        pathContext: paths.context,
      ),
      processLister: McpProcessLister(
        processExecutor: sl<ProcessExecutor>(),
        tools: tools,
        executableName: executableName,
      ),
      activityReader: McpActivityReader(paths: McpActivityPaths(paths)),
      clients: sl<McpClientLocations>().clients,
    );
  });

  sl.registerFactory<McpStatusCubit>(
    () => McpStatusCubit(repository: sl<McpStatusRepository>()),
  );
}
