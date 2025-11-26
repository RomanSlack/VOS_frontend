import 'package:json_annotation/json_annotation.dart';

part 'document_models.g.dart';

/// Document model representing a lightweight data container
@JsonSerializable()
class Document {
  @JsonKey(name: 'document_id')
  final String documentId;
  final String title;
  final String? content;
  @JsonKey(name: 'content_type')
  final String contentType;
  final List<String>? tags;
  @JsonKey(name: 'source_type')
  final String? sourceType;
  @JsonKey(name: 'source_agent_id')
  final String? sourceAgentId;
  @JsonKey(name: 'source_tool')
  final String? sourceTool;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final Map<String, dynamic>? metadata;

  const Document({
    required this.documentId,
    required this.title,
    this.content,
    this.contentType = 'text/plain',
    this.tags,
    this.sourceType,
    this.sourceAgentId,
    this.sourceTool,
    this.sessionId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  /// Get a short preview of the content
  String get contentPreview {
    if (content == null || content!.isEmpty) return '';
    final cleaned = content!.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 100) return cleaned;
    return '${cleaned.substring(0, 100)}...';
  }

  /// Parse the creation timestamp
  DateTime get createdAtDateTime => DateTime.parse(createdAt);

  /// Get the display name for the source agent
  String get sourceAgentDisplayName {
    if (sourceAgentId == null) return 'Unknown';
    // Format agent IDs like "search_agent" to "Search Agent"
    return sourceAgentId!
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Request to create a new document
@JsonSerializable()
class CreateDocumentRequest {
  final String title;
  final String content;
  @JsonKey(name: 'content_type')
  final String? contentType;
  final List<String>? tags;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  const CreateDocumentRequest({
    required this.title,
    required this.content,
    this.contentType,
    this.tags,
    this.sessionId,
    this.metadata,
  });

  factory CreateDocumentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDocumentRequestToJson(this);
}

/// Response containing a list of documents
@JsonSerializable()
class DocumentListResponse {
  final List<Document> documents;
  final int total;
  final int limit;
  final int offset;

  const DocumentListResponse({
    required this.documents,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) =>
      _$DocumentListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentListResponseToJson(this);

  bool get hasMore => offset + documents.length < total;
}

/// Response for delete operation
@JsonSerializable()
class DeleteDocumentResponse {
  final bool success;

  const DeleteDocumentResponse({
    required this.success,
  });

  factory DeleteDocumentResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteDocumentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteDocumentResponseToJson(this);
}

/// WebSocket notification for document creation
@JsonSerializable()
class DocumentCreatedNotification {
  final String type;
  @JsonKey(name: 'document_id')
  final String documentId;
  final String title;
  @JsonKey(name: 'source_agent_id')
  final String? sourceAgentId;

  const DocumentCreatedNotification({
    required this.type,
    required this.documentId,
    required this.title,
    this.sourceAgentId,
  });

  factory DocumentCreatedNotification.fromJson(Map<String, dynamic> json) =>
      _$DocumentCreatedNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentCreatedNotificationToJson(this);
}

/// Parsed document reference from chat message text
class DocumentReference {
  final String documentId;
  final int startIndex;
  final int endIndex;

  const DocumentReference({
    required this.documentId,
    required this.startIndex,
    required this.endIndex,
  });

  /// Extract all document references from a text string
  /// Matches patterns like "doc_abc123" or "document: doc_xyz789"
  static List<DocumentReference> extractFromText(String text) {
    final List<DocumentReference> references = [];
    final regex = RegExp(r'\bdoc_[a-zA-Z0-9]+\b');

    for (final match in regex.allMatches(text)) {
      references.add(DocumentReference(
        documentId: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }

    return references;
  }
}
