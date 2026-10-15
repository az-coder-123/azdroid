import 'package:equatable/equatable.dart';

/// Content object returned inside an MCP Tool Execution Result.
class McpContent extends Equatable {
  const McpContent.text(this.text)
      : type = 'text',
        data = null,
        mimeType = null;

  const McpContent.image({
    required this.data,
    this.mimeType = 'image/png',
  })  : type = 'image',
        text = null;

  final String type;
  final String? text;
  final String? data;
  final String? mimeType;

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text != null) 'text': text,
    if (data != null) 'data': data,
    if (mimeType != null) 'mimeType': mimeType,
  };

  @override
  List<Object?> get props => [type, text, data, mimeType];
}

/// Execution result of an MCP tool invocation.
class McpToolResult extends Equatable {
  const McpToolResult({
    required this.content,
    this.isError = false,
  });

  factory McpToolResult.text(String text) => McpToolResult(
    content: [McpContent.text(text)],
  );

  factory McpToolResult.image({
    required String base64Data,
    String? caption,
    String mimeType = 'image/png',
  }) => McpToolResult(
    content: [
      McpContent.image(data: base64Data, mimeType: mimeType),
      if (caption != null && caption.isNotEmpty) McpContent.text(caption),
    ],
  );

  factory McpToolResult.error(String errorMessage) => McpToolResult(
    content: [McpContent.text(errorMessage)],
    isError: true,
  );

  final List<McpContent> content;
  final bool isError;

  Map<String, dynamic> toJson() => {
    'content': content.map((c) => c.toJson()).toList(),
    if (isError) 'isError': true,
  };

  @override
  List<Object?> get props => [content, isError];
}

/// Tool definition published via the MCP `tools/list` endpoint.
class McpToolDefinition extends Equatable {
  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };

  @override
  List<Object?> get props => [name, description, inputSchema];
}
