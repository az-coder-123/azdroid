import 'package:equatable/equatable.dart';

/// Configuration options passed to `adb install` when sideloading an APK.
class ApkInstallOptions extends Equatable {
  const ApkInstallOptions({
    this.reinstall = true,
    this.grantPermissions = true,
    this.allowDowngrade = false,
    this.allowTestOnly = true,
  });

  /// Replaces existing application keeping its data (`-r`).
  final bool reinstall;

  /// Grants all runtime permissions listed in application manifest (`-g`).
  final bool grantPermissions;

  /// Allows version code downgrade (`-d`).
  final bool allowDowngrade;

  /// Allows test packages (`-t`), common in debug builds.
  final bool allowTestOnly;

  /// Converts configured flags into an argument list for ADB.
  List<String> toCliArgs() {
    final args = <String>[];
    if (reinstall) args.add('-r');
    if (grantPermissions) args.add('-g');
    if (allowDowngrade) args.add('-d');
    if (allowTestOnly) args.add('-t');
    return args;
  }

  /// Creates a copy of options with specific flags updated.
  ApkInstallOptions copyWith({
    bool? reinstall,
    bool? grantPermissions,
    bool? allowDowngrade,
    bool? allowTestOnly,
  }) {
    return ApkInstallOptions(
      reinstall: reinstall ?? this.reinstall,
      grantPermissions: grantPermissions ?? this.grantPermissions,
      allowDowngrade: allowDowngrade ?? this.allowDowngrade,
      allowTestOnly: allowTestOnly ?? this.allowTestOnly,
    );
  }

  @override
  List<Object?> get props => [
    reinstall,
    grantPermissions,
    allowDowngrade,
    allowTestOnly,
  ];
}
