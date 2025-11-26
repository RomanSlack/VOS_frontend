import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/document_models.dart';

part 'document_api.g.dart';

@RestApi(baseUrl: '')
abstract class DocumentApi {
  factory DocumentApi(Dio dio, {String? baseUrl}) = _DocumentApi;

  /// Create a new document
  @POST('/api/v1/docs')
  Future<Document> createDocument(
    @Body() CreateDocumentRequest request,
  );

  /// List documents with optional filters
  @GET('/api/v1/docs')
  Future<DocumentListResponse> listDocuments({
    @Query('session_id') String? sessionId,
    @Query('creator_agent_id') String? creatorAgentId,
    @Query('tags') String? tags, // Comma-separated tags
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Get a specific document by ID
  @GET('/api/v1/docs/{document_id}')
  Future<Document> getDocument(
    @Path('document_id') String documentId,
  );

  /// Delete a document
  @DELETE('/api/v1/docs/{document_id}')
  Future<DeleteDocumentResponse> deleteDocument(
    @Path('document_id') String documentId,
  );
}
