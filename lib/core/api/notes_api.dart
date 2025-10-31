import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/notes_models.dart';

part 'notes_api.g.dart';

@RestApi(baseUrl: '')
abstract class NotesApi {
  factory NotesApi(Dio dio, {String? baseUrl}) = _NotesApi;

  // Execute notes tools via the API Gateway
  @POST('/api/v1/tools/execute')
  Future<ToolExecutionResponse> executeTool(@Body() ToolExecutionRequest request);

  // Subscribe to app interactions (SSE)
  @GET('/api/v1/notifications/app-interaction')
  Future<HttpResponse> subscribeToNotifications({
    @Query('agent_id') String? agentId,
    @Query('app_name') String? appName,
  });
}

/// Helper class to simplify notes tool execution
class NotesToolHelper {
  final NotesApi _api;

  NotesToolHelper(this._api);

  // =========================================================================
  // Notes Tools
  // =========================================================================

  Future<ToolExecutionResponse> createNote(CreateNoteRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'create_note',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> listNotes({
    String? folder,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    required String createdBy,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, dynamic>{
      'created_by': createdBy,
    };

    if (folder != null) {
      params['folder'] = folder;
    }
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags;
    }
    if (isPinned != null) {
      params['is_pinned'] = isPinned;
    }
    if (isArchived != null) {
      params['is_archived'] = isArchived;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (offset != null) {
      params['offset'] = offset;
    }
    if (sortBy != null) {
      params['sort_by'] = sortBy;
    }
    if (sortOrder != null) {
      params['sort_order'] = sortOrder;
    }

    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'list_notes',
        parameters: params,
      ),
    );
  }

  Future<ToolExecutionResponse> getNote({
    required int noteId,
    required String createdBy,
  }) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'get_note',
        parameters: {
          'note_id': noteId,
          'created_by': createdBy,
        },
      ),
    );
  }

  Future<ToolExecutionResponse> updateNote(UpdateNoteRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'update_note',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> deleteNote(DeleteNoteRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'delete_note',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> searchNotes(SearchNotesRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'search_notes',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> archiveNote(ArchiveNoteRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'archive_note',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> pinNote(PinNoteRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'notes_agent',
        toolName: 'pin_note',
        parameters: request.toJson(),
      ),
    );
  }
}
