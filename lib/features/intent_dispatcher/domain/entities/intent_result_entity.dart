import 'package:equatable/equatable.dart';

/// Represents the execution outcome of an Android Intent dispatch command.
class IntentResultEntity extends Equatable {
  const IntentResultEntity({
    required this.success,
    required this.message,
    this.rawOutput = '',
  });

  final bool success;
  final String message;
  final String rawOutput;

  @override
  List<Object?> get props => [success, message, rawOutput];
}
