import 'package:wifi_desk/features/intent_dispatcher/data/datasources/intent_datasource.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_result_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/repositories/intent_repository.dart';

/// Concrete repository implementation managing intent execution.
class IntentRepositoryImpl implements IntentRepository {
  IntentRepositoryImpl({IntentDatasource? datasource})
    : _datasource = datasource ?? IntentDatasourceImpl();

  final IntentDatasource _datasource;

  @override
  Future<IntentResultEntity> dispatchIntent(
    String deviceSerial,
    IntentRequestEntity request,
  ) {
    return _datasource.dispatchIntent(deviceSerial, request);
  }
}
