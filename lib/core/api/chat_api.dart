import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/chat_models.dart';

part 'chat_api.g.dart';

@RestApi(baseUrl: 'http://localhost:8000')
abstract class ChatApi {
  factory ChatApi(Dio dio) = _ChatApi;

  @POST('/api/v1/chat')
  Future<VosMessageResponseDto> sendMessage(@Body() VosMessageRequestDto request);

  @GET('/api/v1/transcript/{agent_id}')
  Future<VosTranscriptResponseDto> getTranscript(
    @Path('agent_id') String agentId, {
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  // Conversation API endpoints
  @GET('/api/v1/conversations/{session_id}')
  Future<ConversationHistoryResponseDto> getConversationHistory(
    @Path('session_id') String sessionId, {
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });
}