import 'package:wifi_desk/core/constants/productivity_constants.dart';
import 'package:wifi_desk/features/productivity/data/datasources/file_transfer_datasource.dart';
import 'package:wifi_desk/features/productivity/domain/entities/remote_file_entity.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';

/// Concrete implementation of [FileTransferRepository] pushing/pulling files and sideloading APKs.
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
  Future<bool> pullFile(
    String deviceSerial,
    String remotePath,
    String localDestination,
  ) {
    return _datasource.pullFile(deviceSerial, remotePath, localDestination);
  }

  @override
  Future<List<RemoteFileEntity>> listRemoteFiles(
    String deviceSerial,
    String remoteDirectory,
  ) {
    return _datasource.listRemoteFiles(deviceSerial, remoteDirectory);
  }

  @override
  Future<bool> installApk(String deviceSerial, String apkPath) {
    return _datasource.installApk(deviceSerial, apkPath);
  }

  @override
  Future<String?> getExternalStorageDirectory(String deviceSerial) {
    return _datasource.getExternalStorageDirectory(deviceSerial);
  }
}
