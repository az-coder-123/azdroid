import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:desk_droid/core/services/app_logger.dart';

/// Entity representing a previously connected device entry for quick 1-click reconnect.
class RecentDevice extends Equatable {
  const RecentDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.lastConnected,
  });

  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final DateTime lastConnected;

  factory RecentDevice.fromJson(Map<String, dynamic> json) {
    return RecentDevice(
      id: json['id'] as String? ?? '${json['ipAddress']}:${json['port']}',
      name: json['name'] as String? ?? 'Android Device',
      ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
      port: json['port'] as int? ?? 5555,
      lastConnected:
          DateTime.tryParse(json['lastConnected'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'lastConnected': lastConnected.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name, ipAddress, port, lastConnected];
}

/// Abstract contract for managing persisted recent device connections.
abstract class DeviceHistoryService {
  Future<List<RecentDevice>> getRecentDevices();
  Future<void> saveRecentDevice(RecentDevice device);
  Future<void> removeRecentDevice(String id);
}

/// Concrete local file-based implementation storing entries at ~/Library/Application Support/DeskDroid/history.json.
class DeviceHistoryServiceImpl implements DeviceHistoryService {
  DeviceHistoryServiceImpl({this.customFilePath});

  final String? customFilePath;
  List<RecentDevice>? _memoryCache;

  File _getHistoryFile() {
    if (customFilePath != null) {
      return File(customFilePath!);
    }
    final home = Platform.environment['HOME'] ?? '';
    final dirPath = '$home/Library/Application Support/DeskDroid';
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('$dirPath/history.json');
  }

  @override
  Future<List<RecentDevice>> getRecentDevices() async {
    if (_memoryCache != null) return _memoryCache!;
    try {
      final file = _getHistoryFile();
      if (!await file.exists()) {
        _memoryCache = [];
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _memoryCache = [];
        return [];
      }
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        _memoryCache =
            decoded
                .map(
                  (item) => RecentDevice.fromJson(item as Map<String, dynamic>),
                )
                .toList()
              ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
        return _memoryCache!;
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load recent devices history',
        error: e,
        stackTrace: stack,
      );
    }
    _memoryCache = [];
    return [];
  }

  @override
  Future<void> saveRecentDevice(RecentDevice device) async {
    final list = await getRecentDevices();
    list.removeWhere(
      (d) => d.id == device.id || d.ipAddress == device.ipAddress,
    );
    list.insert(0, device);
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }
    _memoryCache = list;
    try {
      final file = _getHistoryFile();
      await file.writeAsString(
        jsonEncode(list.map((d) => d.toJson()).toList()),
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to persist recent devices history',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> removeRecentDevice(String id) async {
    final list = await getRecentDevices();
    list.removeWhere((d) => d.id == id);
    _memoryCache = list;
    try {
      final file = _getHistoryFile();
      await file.writeAsString(
        jsonEncode(list.map((d) => d.toJson()).toList()),
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to remove recent device entry',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
