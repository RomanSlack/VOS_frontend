import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/social_models.dart';

part 'social_api.g.dart';

@RestApi(baseUrl: '')
abstract class SocialApi {
  factory SocialApi(Dio dio, {String? baseUrl}) = _SocialApi;

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  /// Get list of conversations for the current user
  @GET('/api/v1/conversations')
  Future<ConversationListResponseDto> getConversations({
    @Query('conversation_type') String? conversationType,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Get a specific conversation
  @GET('/api/v1/conversations/{conversation_id}')
  Future<ConversationDto> getConversation(
    @Path('conversation_id') String conversationId,
  );

  /// Create a new conversation
  @POST('/api/v1/conversations')
  Future<ConversationDto> createConversation(
    @Body() CreateConversationRequestDto request,
  );

  /// Get or create a DM with an agent
  @POST('/api/v1/conversations/dm/{agent_id}')
  Future<ConversationDto> getOrCreateDm(
    @Path('agent_id') String agentId,
  );

  /// Archive a conversation
  @PUT('/api/v1/conversations/{conversation_id}/archive')
  Future<void> archiveConversation(
    @Path('conversation_id') String conversationId,
  );

  /// Leave a conversation
  @DELETE('/api/v1/conversations/{conversation_id}/leave')
  Future<void> leaveConversation(
    @Path('conversation_id') String conversationId,
  );

  // ===========================================================================
  // CONVERSATION MESSAGES
  // ===========================================================================

  /// Get messages in a conversation
  @GET('/api/v1/conversations/{conversation_id}/messages')
  Future<MessageListResponseDto> getMessages(
    @Path('conversation_id') String conversationId, {
    @Query('limit') int? limit,
    @Query('cursor') String? cursor,
  });

  /// Send a message to a conversation
  @POST('/api/v1/conversations/{conversation_id}/messages')
  Future<SocialMessageDto> sendMessage(
    @Path('conversation_id') String conversationId,
    @Body() SendMessageRequestDto request,
  );

  /// Mark conversation as read
  @POST('/api/v1/conversations/{conversation_id}/read')
  Future<void> markAsRead(
    @Path('conversation_id') String conversationId,
  );

  // ===========================================================================
  // AGENT CHATS (PEEK MODE)
  // ===========================================================================

  /// Get agent-to-agent conversations (for peek mode)
  @GET('/api/v1/agent-conversations')
  Future<ConversationListResponseDto> getAgentConversations({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Raise hand to join an agent conversation
  @POST('/api/v1/agent-conversations/{conversation_id}/raise-hand')
  Future<void> raiseHand(
    @Path('conversation_id') String conversationId, {
    @Query('reason') String? reason,
  });

  // ===========================================================================
  // AGENT PROFILES & HEALTH
  // ===========================================================================

  /// Get all agents with their status
  @GET('/api/v1/agents/health')
  Future<AgentListResponseDto> getAgentsWithHealth();

  /// Get online agents only
  @GET('/api/v1/agents/online')
  Future<AgentListResponseDto> getOnlineAgents();

  /// Get a specific agent's profile
  @GET('/api/v1/agents/{agent_id}')
  Future<AgentProfileDto> getAgentProfile(
    @Path('agent_id') String agentId,
  );

  /// Get agent's health status
  @GET('/api/v1/agents/{agent_id}/health')
  Future<AgentHealthDto> getAgentHealth(
    @Path('agent_id') String agentId,
  );

  // ===========================================================================
  // FEED (STATUSES & STORIES)
  // ===========================================================================

  /// Get combined feed (statuses + stories)
  @GET('/api/v1/feed')
  Future<FeedResponseDto> getFeed({
    @Query('limit') int? limit,
  });

  /// Get all active statuses
  @GET('/api/v1/feed/statuses')
  Future<List<AgentStatusDto>> getStatuses({
    @Query('limit') int? limit,
  });

  /// Get all active stories
  @GET('/api/v1/feed/stories')
  Future<List<AgentStoryDto>> getStories({
    @Query('limit') int? limit,
  });

  /// Get a specific agent's current status
  @GET('/api/v1/feed/agents/{agent_id}/status')
  Future<AgentStatusDto?> getAgentStatus(
    @Path('agent_id') String agentId,
  );

  /// Get a specific agent's stories
  @GET('/api/v1/feed/agents/{agent_id}/stories')
  Future<List<AgentStoryDto>> getAgentStories(
    @Path('agent_id') String agentId,
  );

  /// Mark a story as viewed
  @POST('/api/v1/feed/stories/{story_id}/view')
  Future<void> viewStory(
    @Path('story_id') String storyId,
  );
}
