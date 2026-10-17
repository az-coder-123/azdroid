import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/entities/intent_result_entity.dart';
import 'package:equatable/equatable.dart';

/// Base state for the Intent Dispatcher feature.
sealed class IntentDispatcherState extends Equatable {
  const IntentDispatcherState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state.
class IntentDispatcherInitial extends IntentDispatcherState {
  const IntentDispatcherInitial();
}

/// State emitted while an intent is actively being dispatched via ADB.
class IntentDispatcherSending extends IntentDispatcherState {
  const IntentDispatcherSending();
}

/// State emitted when the intent was successfully dispatched without errors.
class IntentDispatcherSuccess extends IntentDispatcherState {
  const IntentDispatcherSuccess({required this.result, required this.request});

  final IntentResultEntity result;
  final IntentRequestEntity request;

  @override
  List<Object?> get props => [result, request];
}

/// State emitted when intent dispatch failed or resulted in an Android exception.
class IntentDispatcherFailure extends IntentDispatcherState {
  const IntentDispatcherFailure({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
