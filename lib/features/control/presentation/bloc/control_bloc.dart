import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_event.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC orchestrating remote input injection, gesture debouncing, and keyboard state.
class ControlBloc extends Bloc<ControlEvent, ControlState> {
  ControlBloc({required this.repository}) : super(const ControlReady()) {
    on<ControlTapDispatched>(_onTapDispatched);
    on<ControlSwipeDispatched>(_onSwipeDispatched);
    on<ControlScrollDispatched>(_onScrollDispatched);
    on<ControlKeyDispatched>(_onKeyDispatched);
    on<ControlTextDispatched>(_onTextDispatched);
    on<ControlNavigationActionDispatched>(_onNavigationActionDispatched);
    on<ControlKeyboardCaptureToggled>(_onKeyboardCaptureToggled);
    // A stream's DOWN, MOVEs, and UP must reach the device in order.
    on<ControlTouchStreamed>(_onTouchStreamed, transformer: _sequential());
  }

  /// Handles one event at a time, in arrival order.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  /// Moves arrive at the trackpad rate (60–120 Hz), so only the start
  /// failure and the end are reported in the state.
  Future<void> _onTouchStreamed(
    ControlTouchStreamed event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendTouchStream(
      event.deviceSerial,
      event.phase,
      event.points,
    );
    if (!success && event.phase == TouchStreamPhase.start) {
      emit(
        ControlError(
          errorMessage: 'Failed to inject touch',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    } else if (success && event.phase == TouchStreamPhase.end) {
      final fingers = event.points.length;
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: fingers > 1 ? 'Pinch' : 'Drag',
        ),
      );
    }
  }

  final ControlRepository repository;
  DateTime _lastScrollTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _onTapDispatched(
    ControlTapDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendTap(
      event.deviceSerial,
      normalizedX: event.normalizedX,
      normalizedY: event.normalizedY,
    );

    if (success) {
      final xPct = (event.normalizedX * 100).toStringAsFixed(0);
      final yPct = (event.normalizedY * 100).toStringAsFixed(0);
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Tap ($xPct%, $yPct%)',
        ),
      );
    } else {
      emit(
        ControlError(
          errorMessage: 'Failed to inject tap on ${event.deviceSerial}',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    }
  }

  Future<void> _onSwipeDispatched(
    ControlSwipeDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendSwipe(
      event.deviceSerial,
      startX: event.startX,
      startY: event.startY,
      endX: event.endX,
      endY: event.endY,
      durationMs: event.durationMs,
    );

    if (success) {
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Swipe',
        ),
      );
    } else {
      emit(
        ControlError(
          errorMessage: 'Failed to inject swipe',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    }
  }

  Future<void> _onScrollDispatched(
    ControlScrollDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inMilliseconds <
        ControlConstants.pointerThrottleMs) {
      return; // Throttle excessive scroll flings
    }
    _lastScrollTime = now;

    final success = await repository.sendScroll(
      event.deviceSerial,
      normalizedX: event.normalizedX,
      normalizedY: event.normalizedY,
      deltaX: event.deltaX,
      deltaY: event.deltaY,
    );

    if (success) {
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Scroll',
        ),
      );
    }
  }

  Future<void> _onKeyDispatched(
    ControlKeyDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendKeyEvent(
      event.deviceSerial,
      event.keyCode,
    );

    if (success) {
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Key (${event.keyCode})',
        ),
      );
    } else {
      emit(
        ControlError(
          errorMessage: 'Failed to inject key ${event.keyCode}',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    }
  }

  Future<void> _onTextDispatched(
    ControlTextDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendText(event.deviceSerial, event.text);

    if (success) {
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Text (${event.text.length} chars)',
        ),
      );
    } else {
      emit(
        ControlError(
          errorMessage: 'Failed to inject text',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    }
  }

  Future<void> _onNavigationActionDispatched(
    ControlNavigationActionDispatched event,
    Emitter<ControlState> emit,
  ) async {
    final success = await repository.sendNavigationAction(
      event.deviceSerial,
      event.action,
    );

    if (success) {
      emit(
        ControlReady(
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount + 1,
          lastActionDescription: 'Action (${event.action.name})',
        ),
      );
    } else {
      emit(
        ControlError(
          errorMessage: 'Failed to inject action ${event.action.name}',
          isKeyboardCaptured: state.isKeyboardCaptured,
          injectedCount: state.injectedCount,
        ),
      );
    }
  }

  void _onKeyboardCaptureToggled(
    ControlKeyboardCaptureToggled event,
    Emitter<ControlState> emit,
  ) {
    emit(
      ControlReady(
        isKeyboardCaptured: event.isCaptured,
        injectedCount: state.injectedCount,
        lastActionDescription: state.lastActionDescription,
      ),
    );
  }
}
