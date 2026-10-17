/// How long transient user feedback stays visible.
class FeedbackDurations {
  const FeedbackDurations._();

  /// Delay before a successful dialog closes itself.
  static const Duration dialogAutoClose = Duration(milliseconds: 900);

  /// "Copied" confirmation shown on copy buttons.
  static const Duration copyConfirmation = Duration(seconds: 2);

  /// Floating snack bar messages.
  static const Duration snackBar = Duration(seconds: 3);

  /// Transfer and clipboard status banners before returning to idle.
  static const Duration statusBanner = Duration(seconds: 4);

  /// Screenshot and recording result cards before auto-dismiss.
  static const Duration captureResultCard = Duration(seconds: 6);
}
