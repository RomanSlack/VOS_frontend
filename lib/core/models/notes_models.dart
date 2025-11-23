import 'package:json_annotation/json_annotation.dart';

part 'notes_models.g.dart';

// ============================================================================
// Note Models
// ============================================================================

@JsonSerializable()
class Note {
  final int id;
  final String title;
  final String? content;
  @JsonKey(name: 'content_preview')
  final String? contentPreview;
  final List<String>? tags;
  final String? folder;
  final String? color;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'content_length')
  final int contentLength;
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'has_gcs_content')
  final bool? hasGcsContent;
  @JsonKey(name: 'storage_location')
  final String? storageLocation;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    this.content,
    this.contentPreview,
    this.tags,
    this.folder,
    this.color,
    this.contentType = 'text/plain',
    this.contentLength = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.hasGcsContent,
    this.storageLocation,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  Map<String, dynamic> toJson() => _$NoteToJson(this);

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? contentPreview,
    List<String>? tags,
    String? folder,
    String? color,
    String? contentType,
    int? contentLength,
    bool? isPinned,
    bool? isArchived,
    bool? hasGcsContent,
    String? storageLocation,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentPreview: contentPreview ?? this.contentPreview,
      tags: tags ?? this.tags,
      folder: folder ?? this.folder,
      color: color ?? this.color,
      contentType: contentType ?? this.contentType,
      contentLength: contentLength ?? this.contentLength,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      hasGcsContent: hasGcsContent ?? this.hasGcsContent,
      storageLocation: storageLocation ?? this.storageLocation,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// Tool Execution Models (Shared with Calendar/Weather)
// ============================================================================

@JsonSerializable()
class ToolExecutionRequest {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'tool_name')
  final String toolName;
  final Map<String, dynamic> parameters;

  ToolExecutionRequest({
    required this.agentId,
    required this.toolName,
    required this.parameters,
  });

  factory ToolExecutionRequest.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionRequestToJson(this);
}

@JsonSerializable()
class ToolExecutionResponse {
  final String status;
  final String? message;
  final Map<String, dynamic>? result;
  final String? error;

  ToolExecutionResponse({
    required this.status,
    this.message,
    this.result,
    this.error,
  });

  factory ToolExecutionResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionResponseToJson(this);
}

// ============================================================================
// Notes Tool Request Models
// ============================================================================

@JsonSerializable()
class CreateNoteRequest {
  final String title;
  final String content;
  final List<String>? tags;
  final String? folder;
  final String? color;
  @JsonKey(name: 'content_type')
  final String? contentType;
  @JsonKey(name: 'is_pinned')
  final bool? isPinned;
  @JsonKey(name: 'created_by')
  final String createdBy;

  CreateNoteRequest({
    required this.title,
    required this.content,
    this.tags,
    this.folder,
    this.color,
    this.contentType,
    this.isPinned,
    required this.createdBy,
  });

  factory CreateNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteRequestToJson(this);
}

@JsonSerializable()
class UpdateNoteRequest {
  @JsonKey(name: 'note_id')
  final int noteId;
  final String? title;
  final String? content;
  final List<String>? tags;
  final String? folder;
  final String? color;
  @JsonKey(name: 'is_pinned')
  final bool? isPinned;
  @JsonKey(name: 'created_by')
  final String createdBy;

  UpdateNoteRequest({
    required this.noteId,
    this.title,
    this.content,
    this.tags,
    this.folder,
    this.color,
    this.isPinned,
    required this.createdBy,
  });

  factory UpdateNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoteRequestToJson(this);
}

@JsonSerializable()
class DeleteNoteRequest {
  @JsonKey(name: 'note_id')
  final int noteId;
  @JsonKey(name: 'created_by', includeIfNull: false)
  final String? createdBy;

  DeleteNoteRequest({
    required this.noteId,
    this.createdBy,
  });

  factory DeleteNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteNoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteNoteRequestToJson(this);
}

@JsonSerializable()
class SearchNotesRequest {
  final String query;
  @JsonKey(name: 'created_by')
  final String createdBy;
  final String? folder;
  final List<String>? tags;
  final int? limit;

  SearchNotesRequest({
    required this.query,
    required this.createdBy,
    this.folder,
    this.tags,
    this.limit,
  });

  factory SearchNotesRequest.fromJson(Map<String, dynamic> json) =>
      _$SearchNotesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SearchNotesRequestToJson(this);
}

@JsonSerializable()
class SemanticSearchRequest {
  final String query;
  final int? limit;
  final List<String>? tags;
  final String? folder;
  final double? alpha;
  @JsonKey(name: 'search_type')
  final String? searchType;
  @JsonKey(name: 'fetch_full')
  final bool? fetchFull;

  SemanticSearchRequest({
    required this.query,
    this.limit,
    this.tags,
    this.folder,
    this.alpha,
    this.searchType,
    this.fetchFull,
  });

  factory SemanticSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$SemanticSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SemanticSearchRequestToJson(this);
}

@JsonSerializable()
class SemanticSearchResult {
  final Note note;
  final double? score;
  final double? distance;

  SemanticSearchResult({
    required this.note,
    this.score,
    this.distance,
  });

  factory SemanticSearchResult.fromJson(Map<String, dynamic> json) =>
      _$SemanticSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SemanticSearchResultToJson(this);
}

@JsonSerializable()
class ArchiveNoteRequest {
  @JsonKey(name: 'note_id')
  final int noteId;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'created_by')
  final String createdBy;

  ArchiveNoteRequest({
    required this.noteId,
    required this.isArchived,
    required this.createdBy,
  });

  factory ArchiveNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$ArchiveNoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ArchiveNoteRequestToJson(this);
}

@JsonSerializable()
class PinNoteRequest {
  @JsonKey(name: 'note_id')
  final int noteId;
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @JsonKey(name: 'created_by')
  final String createdBy;

  PinNoteRequest({
    required this.noteId,
    required this.isPinned,
    required this.createdBy,
  });

  factory PinNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$PinNoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PinNoteRequestToJson(this);
}

// ============================================================================
// Notes List Response
// ============================================================================

@JsonSerializable()
class NotesListResponse {
  final List<Note> notes;
  @JsonKey(name: 'total_count')
  final int totalCount;
  final int limit;
  final int offset;
  @JsonKey(name: 'has_more')
  final bool hasMore;

  NotesListResponse({
    required this.notes,
    required this.totalCount,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory NotesListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotesListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotesListResponseToJson(this);
}

// ============================================================================
// Notes Search Response
// ============================================================================

@JsonSerializable()
class NotesSearchResponse {
  final List<Note> notes;
  final String query;
  final int count;

  NotesSearchResponse({
    required this.notes,
    required this.query,
    required this.count,
  });

  factory NotesSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$NotesSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotesSearchResponseToJson(this);
}
