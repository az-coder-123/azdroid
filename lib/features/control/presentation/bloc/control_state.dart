import 'package:equatable/equatable.dart';

/// Base state for remote control input processing.
sealed class ControlState extends Equatable {
  const ControlState({
    this.isKeyboardCaptured = true,
    this.injectedCount = 0,
    this.lastActionDescription,
  });

  /// Whether the overlay currently holds keyboard input capture focus.
  final bool isKeyboardCaptured;

  /// Running count of successfully dispatched input actions.
  final int injectedCount;

  /// Readable description of the most recently executed action for HUD telemetry.
  final String? lastActionDescription;

  @override
  List<Object?> get props => [
    isKeyboardCaptured,
    injectedCount,
    lastActionDescription,
  ];
}

/// Initial uninitialized state.
class ControlInitial extends ControlState {
  const ControlInitial() : super();
}

/// Ready state indicating active responsiveness.
class ControlReady extends ControlState {
  const ControlReady({
    super.isKeyboardCaptured,
    super.injectedCount,
    super.lastActionDescription,
  });

  ControlReady copyWith({
    bool? isKeyboardCaptured,
    int? injectedCount,
    String? lastActionDescription,
  }) {
    return ControlReady(
      isKeyboardCaptured: isKeyboardCaptured ?? this.isKeyboardCaptured,
      injectedCount: injectedCount ?? this.injectedCount,
      lastActionDescription:
          lastActionDescription ?? this.lastActionDescription,
    );
  }
}

/// Error state emitted when input dispatch fails.
class ControlError extends ControlState {
  const ControlError({
    required this.errorMessage,
    super.isKeyboardCaptured,
    super.injectedCount,
    super.lastActionDescription,
  });

  final String errorMessage;

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
