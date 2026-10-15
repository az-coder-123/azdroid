import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_result_entity.dart';

/// Abstract repository contract for firing intents and deep links to Android devices.
abstract class IntentRepository {
  /// Dispatches an Android intent via ADB to the specified device.
  Future<IntentResultEntity> dispatchIntent(
    String deviceSerial,
    IntentRequestEntity request,
  );
}
