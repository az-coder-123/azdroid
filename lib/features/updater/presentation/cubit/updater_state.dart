import 'package:desk_droid/features/updater/domain/entities/app_update_info.dart';
import 'package:equatable/equatable.dart';

/// Base class for states emitted by [UpdaterCubit].
sealed class UpdaterState extends Equatable {
  const UpdaterState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any update verification has been initiated.
class UpdaterInitial extends UpdaterState {
  const UpdaterInitial();
}

/// State emitted while querying remote release repositories.
class UpdaterChecking extends UpdaterState {
  const UpdaterChecking();
}

/// State emitted when a newer release is validated and ready for installation.
class UpdaterAvailable extends UpdaterState {
  const UpdaterAvailable({
    required this.updateInfo,
    this.isBannerDismissed = false,
  });

  final AppUpdateInfo updateInfo;

  /// Whether the user temporarily dismissed the inline notification banner.
  final bool isBannerDismissed;

  UpdaterAvailable copyWith({bool? isBannerDismissed}) {
    return UpdaterAvailable(
      updateInfo: updateInfo,
      isBannerDismissed: isBannerDismissed ?? this.isBannerDismissed,
    );
  }

  @override
  List<Object?> get props => [updateInfo, isBannerDismissed];
}

/// State emitted when the current installed version is the latest known release.
class UpdaterUpToDate extends UpdaterState {
  const UpdaterUpToDate({required this.currentVersion});

  final String currentVersion;

  @override
  List<Object?> get props => [currentVersion];
}

/// State emitted when update discovery fails due to network or rate limiting.
class UpdaterFailure extends UpdaterState {
  const UpdaterFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
