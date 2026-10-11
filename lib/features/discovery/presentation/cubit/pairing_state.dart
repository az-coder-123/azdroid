import 'package:equatable/equatable.dart';

/// Base class for states emitted during the wireless pairing process.
sealed class PairingState extends Equatable {
  const PairingState();

  @override
  List<Object?> get props => [];
}

/// Initial state awaiting user input.
final class PairingInitial extends PairingState {
  const PairingInitial();
}

/// State emitted while actively executing `adb pair`.
final class PairingSubmitting extends PairingState {
  const PairingSubmitting();
}

/// State emitted when device pairing completes successfully.
final class PairingSuccess extends PairingState {
  const PairingSuccess({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// State emitted when device pairing encounters an error or timeout.
final class PairingFailure extends PairingState {
  const PairingFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
