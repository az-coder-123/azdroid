import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_state.dart';

/// Cubit managing Android 11+ wireless pairing workflow.
class PairingCubit extends Cubit<PairingState> {
  PairingCubit({required this.repository}) : super(const PairingInitial());

  final DeviceDiscoveryRepository repository;

  /// Executes pairing via ADB wireless pairing credentials.
  Future<void> pair({
    required String ipAddress,
    required int port,
    required String pairingCode,
  }) async {
    final cleanIp = ipAddress.trim();
    final cleanCode = pairingCode.trim();

    if (cleanIp.isEmpty) {
      emit(const PairingFailure(error: 'IP Address cannot be empty.'));
      return;
    }

    if (cleanCode.length != 6) {
      emit(
        const PairingFailure(error: 'Pairing code must be exactly 6 digits.'),
      );
      return;
    }

    emit(const PairingSubmitting());
    try {
      final success = await repository.pairDevice(
        ipAddress: cleanIp,
        port: port,
        pairingCode: cleanCode,
      );

      if (success) {
        emit(
          PairingSuccess(
            message: 'Device successfully paired at $cleanIp:$port!',
          ),
        );
      } else {
        emit(
          const PairingFailure(
            error: 'Pairing rejected. Please ensure the pairing dialog is currently open on your phone.',
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Pairing failed for $cleanIp:$port',
        error: e,
        stackTrace: stack,
      );
      emit(PairingFailure(error: 'Pairing exception: $e'));
    }
  }

  /// Resets state back to initial form.
  void reset() {
    emit(const PairingInitial());
  }
}
