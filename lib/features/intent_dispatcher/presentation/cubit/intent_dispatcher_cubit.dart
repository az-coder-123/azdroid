import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/repositories/intent_repository.dart';
import 'package:wifi_desk/features/intent_dispatcher/presentation/cubit/intent_dispatcher_state.dart';

/// Cubit managing intent and deep link dispatching to an active Android device.
class IntentDispatcherCubit extends Cubit<IntentDispatcherState> {
  IntentDispatcherCubit({required this.repository})
    : super(const IntentDispatcherInitial());

  final IntentRepository repository;

  /// Resets state back to idle.
  void reset() {
    emit(const IntentDispatcherInitial());
  }

  /// Dispatches the configured intent to the target device.
  Future<void> dispatchIntent(
    String deviceSerial,
    IntentRequestEntity request,
  ) async {
    if ((request.dataUri == null || request.dataUri!.trim().isEmpty) &&
        (request.packageName == null || request.packageName!.trim().isEmpty) &&
        (request.componentName == null ||
            request.componentName!.trim().isEmpty)) {
      emit(
        const IntentDispatcherFailure(
          errorMessage:
              'Please provide at least a Data URI, Package Name, or Component.',
        ),
      );
      return;
    }

    emit(const IntentDispatcherSending());

    final result = await repository.dispatchIntent(deviceSerial, request);

    if (isClosed) return;

    if (result.success) {
      emit(IntentDispatcherSuccess(result: result, request: request));
    } else {
      emit(IntentDispatcherFailure(errorMessage: result.message));
    }
  }
}
