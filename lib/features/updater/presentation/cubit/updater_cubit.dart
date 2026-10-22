import 'package:desk_droid/core/constants/app_constants.dart';
import 'package:desk_droid/core/constants/update_constants.dart';
import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';
import 'package:desk_droid/features/updater/domain/repositories/update_repository.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing background version discovery, caching, and update actions.
class UpdaterCubit extends Cubit<UpdaterState> {
  UpdaterCubit({
    required this.updateRepository,
    required this.fileLauncher,
    this.currentVersion = AppConstants.appVersion,
  }) : super(const UpdaterInitial());

  final UpdateRepository updateRepository;
  final HostFileLauncher fileLauncher;
  final String currentVersion;

  /// Checks for newer releases.
  ///
  /// If [force] is true, queries GitHub regardless of cache or throttle status.
  Future<void> checkForUpdates({bool force = false}) async {
    emit(const UpdaterChecking());

    try {
      final info = await updateRepository.checkForUpdate(
        currentVersionRaw: currentVersion,
        force: force,
      );

      if (info != null) {
        emit(UpdaterAvailable(updateInfo: info));
      } else {
        emit(UpdaterUpToDate(currentVersion: currentVersion));
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to complete update verification',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const UpdaterFailure(message: 'Unable to check for updates.'));
    }
  }

  /// Temporarily hides the top notification banner for this session.
  void dismissBanner() {
    final current = state;
    if (current is UpdaterAvailable) {
      emit(current.copyWith(isBannerDismissed: true));
    }
  }

  /// Opens the target download URL in the host's default web browser.
  Future<bool> launchDownload(AppUpdateInfo info) async {
    final targetUrl = info.downloadUrl ?? info.htmlUrl;
    return fileLauncher.open(targetUrl);
  }

  /// Opens the project releases web page on GitHub.
  Future<bool> launchReleasesPage() async {
    return fileLauncher.open(UpdateConstants.releasesWebUrl);
  }
}
