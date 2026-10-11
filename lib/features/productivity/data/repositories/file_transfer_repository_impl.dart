import 'package:wifi_desk/core/constants/productivity_constants.dart';
import 'package:wifi_desk/features/productivity/data/datasources/file_transfer_datasource.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';

/// Concrete implementation of [FileTransferRepository] pushing files and sideloading APKs.
class FileTransferRepositoryImpl implements FileTransferRepository {
  FileTransferRepositoryImpl({FileTransferDatasource? datasource})
    : _datasource = datasource ?? FileTransferDatasourceImpl();

  final FileTransferDatasource _datasource;

  @override
  Future<bool> pushFile(
    String deviceSerial,
    String localPath, {
    String? remoteDestination,
  }) {
    final destination =
        remoteDestination ?? ProductivityConstants.defaultRemoteDownloadDir;
    return _datasource.pushFile(deviceSerial, localPath, destination);
  }

  @override
  Future<bool> installApk(String deviceSerial, String apkPath) {
    return _datasource.installApk(deviceSerial, apkPath);
  }
}
