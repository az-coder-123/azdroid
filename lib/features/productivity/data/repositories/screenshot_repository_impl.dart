import 'package:wifi_desk/features/productivity/data/datasources/screenshot_datasource.dart';
import 'package:wifi_desk/features/productivity/domain/entities/screenshot_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screenshot_repository.dart';

/// Implementation of [ScreenshotRepository] delegating to [ScreenshotDatasource].
class ScreenshotRepositoryImpl implements ScreenshotRepository {
  const ScreenshotRepositoryImpl({required this.datasource});

  final ScreenshotDatasource datasource;

  @override
  Future<ScreenshotEntity?> captureScreenshot({
    required String deviceSerial,
    String? customSaveDirectory,
  }) {
    return datasource.captureScreenshot(
      deviceSerial: deviceSerial,
      customSaveDirectory: customSaveDirectory,
    );
  }
}
