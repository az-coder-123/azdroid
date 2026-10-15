import 'package:desk_droid/features/productivity/data/datasources/clipboard_datasource.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';

/// Concrete implementation of [ClipboardRepository] managing bidirectional text syncing.
class ClipboardRepositoryImpl implements ClipboardRepository {
  ClipboardRepositoryImpl({ClipboardDatasource? datasource})
    : _datasource = datasource ?? ClipboardDatasourceImpl();

  final ClipboardDatasource _datasource;

  @override
  Future<String?> getHostClipboard() => _datasource.readHostClipboard();

  @override
  Future<void> setHostClipboard(String text) =>
      _datasource.writeHostClipboard(text);

  @override
  Future<String?> getDeviceClipboard(String deviceSerial) =>
      _datasource.readDeviceClipboard(deviceSerial);

  @override
  Future<bool> setDeviceClipboard(String deviceSerial, String text) =>
      _datasource.writeDeviceClipboard(deviceSerial, text);

  @override
  Future<bool> syncHostToDevice(String deviceSerial) async {
    final hostText = await getHostClipboard();
    if (hostText == null || hostText.isEmpty) return false;
    return setDeviceClipboard(deviceSerial, hostText);
  }

  @override
  Future<bool> syncDeviceToHost(String deviceSerial) async {
    final deviceText = await getDeviceClipboard(deviceSerial);
    if (deviceText == null || deviceText.isEmpty) return false;
    await setHostClipboard(deviceText);
    return true;
  }
}
