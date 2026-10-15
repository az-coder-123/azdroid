import 'package:equatable/equatable.dart';

/// Standard JSON-RPC 2.0 error representation according to MCP specifications.
class McpError extends Equatable {
  const McpError({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final dynamic data;

  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };

  factory McpError.fromJson(Map<String, dynamic> json) => McpError(
    code: json['code'] as int? ?? internalError,
    message: json['message'] as String? ?? 'Unknown error',
    data: json['data'],
  );

  @override
  List<Object?> get props => [code, message, data];
}

/// Incoming JSON-RPC 2.0 Request or Notification.
class McpRequest extends Equatable {
  const McpRequest({
    required this.method,
    this.id,
    this.params,
    this.jsonrpc = '2.0',
  });

  final String jsonrpc;
  final dynamic id;
  final String method;
  final Map<String, dynamic>? params;

  bool get isNotification => id == null;

  factory McpRequest.fromJson(Map<String, dynamic> json) {
    return McpRequest(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id'],
      method: json['method'] as String? ?? '',
      params: json['params'] is Map<String, dynamic>
          ? json['params'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    if (id != null) 'id': id,
    'method': method,
    if (params != null) 'params': params,
  };

  @override
  List<Object?> get props => [jsonrpc, id, method, params];
}

/// Outgoing JSON-RPC 2.0 Response.
class McpResponse extends Equatable {
  const McpResponse({
    this.id,
    this.result,
    this.error,
    this.jsonrpc = '2.0',
  });

  final String jsonrpc;
  final dynamic id;
  final dynamic result;
  final McpError? error;

  bool get isSuccess => error == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'jsonrpc': jsonrpc,
      'id': id,
    };
    if (error != null) {
      map['error'] = error!.toJson();
    } else {
      map['result'] = result ?? <String, dynamic>{};
    }
    return map;
  }

  @override
  List<Object?> get props => [jsonrpc, id, result, error];
}
