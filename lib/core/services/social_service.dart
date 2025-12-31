import 'dart:async';
import 'package:dio/dio.dart';
import 'package:vos_app/core/api/social_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:logging/logging.dart';

final _log = Logger('SocialService');

class SocialService {
  late final SocialApi _api;
  late final Dio _dio;
  final AuthService _authService = AuthService();

  // Cached data for quick access
  List<AgentProfileDto> _cachedAgents = [];
  DateTime? _agentsCacheTime;
  static const _agentsCacheDuration = Duration(minutes: 5);

  SocialService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add API key
          options.headers['X-API-Key'] = AppConfig.apiKey;

          // Add JWT token if available
          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          _log.warning('API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );

    _api = SocialApi(_dio);
  }

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  /// Get all conversations for the current user
  Future<List<ConversationDto>> getConversations({
    ConversationType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.getConversations(
        conversationType: type?.name,
        limit: limit,
        offset: offset,
      );
      return response.conversations;
    } catch (e) {
      _log.severe('Failed to get conversations: $e');
      rethrow;
    }
  }

  /// Get DMs only
  Future<List<ConversationDto>> getDMs({int limit = 50}) async {
    return getConversations(type: ConversationType.dm, limit: limit);
  }

  /// Get groups only
  Future<List<ConversationDto>> getGroups({int limit = 50}) async {
    return getConversations(type: ConversationType.group, limit: limit);
  }

  /// Get a specific conversation
  Future<ConversationDto> getConversation(String conversationId) async {
    try {
      return await _api.getConversation(conversationId);
    } catch (e) {
      _log.severe('Failed to get conversation $conversationId: $e');
      rethrow;
    }
  }

  /// Start or get existing DM with an agent
  Future<ConversationDto> startDmWithAgent(String agentId) async {
    try {
      return await _api.getOrCreateDm(agentId);
    } catch (e) {
      _log.severe('Failed to start DM with $agentId: $e');
      rethrow;
    }
  }

  /// Create a group conversation
  Future<ConversationDto> createGroup({
    required String name,
    required List<String> agentIds,
    List<String>? userIds,
  }) async {
    try {
      final participants = <ConversationParticipantDto>[];

      for (final agentId in agentIds) {
        participants.add(ConversationParticipantDto(
          participantType: ParticipantType.agent,
          participantId: agentId,
        ));
      }

      if (userIds != null) {
        for (final userId in userIds) {
          participants.add(ConversationParticipantDto(
            participantType: ParticipantType.user,
            participantId: userId,
          ));
        }
      }

      return await _api.createConversation(CreateConversationRequestDto(
        conversationType: ConversationType.group,
        name: name,
        participants: participants,
      ));
    } catch (e) {
      _log.severe('Failed to create group: $e');
      rethrow;
    }
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _api.archiveConversation(conversationId);
    } catch (e) {
      _log.severe('Failed to archive conversation: $e');
      rethrow;
    }
  }

  /// Leave a conversation
  Future<void> leaveConversation(String conversationId) async {
    try {
      await _api.leaveConversation(conversationId);
    } catch (e) {
      _log.severe('Failed to leave conversation: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  /// Get messages from a conversation
  Future<MessageListResponseDto> getMessages(
    String conversationId, {
    int limit = 50,
    String? cursor,
  }) async {
    try {
      return await _api.getMessages(
        conversationId,
        limit: limit,
        cursor: cursor,
      );
    } catch (e) {
      _log.severe('Failed to get messages for $conversationId: $e');
      rethrow;
    }
  }

  /// Send a message to a conversation
  Future<SocialMessageDto> sendMessage(
    String conversationId, {
    required String content,
    String contentType = 'text',
    String? replyToId,
    List<String>? attachments,
  }) async {
    try {
      return await _api.sendMessage(
        conversationId,
        SendMessageRequestDto(
          content: content,
          contentType: contentType,
          replyToId: replyToId,
          attachments: attachments,
        ),
      );
    } catch (e) {
      _log.severe('Failed to send message to $conversationId: $e');
      rethrow;
    }
  }

  /// Mark a conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _api.markAsRead(conversationId);
    } catch (e) {
      _log.warning('Failed to mark conversation as read: $e');
      // Don't rethrow - non-critical operation
    }
  }

  // ===========================================================================
  // AGENT CHATS (PEEK MODE)
  // ===========================================================================

  /// Get agent-to-agent conversations for peek mode
  Future<List<ConversationDto>> getAgentConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.getAgentConversations(
        limit: limit,
        offset: offset,
      );
      return response.conversations;
    } catch (e) {
      _log.severe('Failed to get agent conversations: $e');
      rethrow;
    }
  }

  /// Raise hand to join an agent conversation
  Future<void> raiseHand(String conversationId, {String? reason}) async {
    try {
      await _api.raiseHand(conversationId, reason: reason);
    } catch (e) {
      _log.severe('Failed to raise hand: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // AGENT PROFILES & HEALTH
  // ===========================================================================

  /// Get all agents with their health status
  Future<List<AgentProfileDto>> getAgents({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh &&
        _cachedAgents.isNotEmpty &&
        _agentsCacheTime != null &&
        DateTime.now().difference(_agentsCacheTime!) < _agentsCacheDuration) {
      return _cachedAgents;
    }

    try {
      final response = await _api.getAgentsWithHealth();
      _cachedAgents = response.agents;
      _agentsCacheTime = DateTime.now();
      return _cachedAgents;
    } catch (e) {
      _log.severe('Failed to get agents: $e');
      // Return cached data if available
      if (_cachedAgents.isNotEmpty) {
        return _cachedAgents;
      }
      rethrow;
    }
  }

  /// Get only online agents
  Future<List<AgentProfileDto>> getOnlineAgents() async {
    try {
      final response = await _api.getOnlineAgents();
      return response.agents;
    } catch (e) {
      _log.severe('Failed to get online agents: $e');
      rethrow;
    }
  }

  /// Get a specific agent's profile
  Future<AgentProfileDto> getAgentProfile(String agentId) async {
    try {
      return await _api.getAgentProfile(agentId);
    } catch (e) {
      _log.severe('Failed to get agent profile $agentId: $e');
      rethrow;
    }
  }

  /// Get agent's health status
  Future<AgentHealthDto> getAgentHealth(String agentId) async {
    try {
      return await _api.getAgentHealth(agentId);
    } catch (e) {
      _log.severe('Failed to get agent health $agentId: $e');
      rethrow;
    }
  }

  /// Check if a specific agent is online (from cache)
  bool isAgentOnline(String agentId) {
    final agent = _cachedAgents.where((a) => a.agentId == agentId).firstOrNull;
    return agent?.isOnline ?? false;
  }

  // ===========================================================================
  // FEED (STATUSES & STORIES)
  // ===========================================================================

  /// Get the combined feed
  Future<FeedResponseDto> getFeed({int limit = 50}) async {
    try {
      return await _api.getFeed(limit: limit);
    } catch (e) {
      _log.severe('Failed to get feed: $e');
      rethrow;
    }
  }

  /// Get all active statuses
  Future<List<AgentStatusDto>> getStatuses({int limit = 50}) async {
    try {
      return await _api.getStatuses(limit: limit);
    } catch (e) {
      _log.severe('Failed to get statuses: $e');
      rethrow;
    }
  }

  /// Get all active stories
  Future<List<AgentStoryDto>> getStories({int limit = 50}) async {
    try {
      return await _api.getStories(limit: limit);
    } catch (e) {
      _log.severe('Failed to get stories: $e');
      rethrow;
    }
  }

  /// Get a specific agent's current status
  Future<AgentStatusDto?> getAgentStatus(String agentId) async {
    try {
      return await _api.getAgentStatus(agentId);
    } catch (e) {
      _log.warning('Failed to get agent status $agentId: $e');
      return null;
    }
  }

  /// Get a specific agent's stories
  Future<List<AgentStoryDto>> getAgentStories(String agentId) async {
    try {
      return await _api.getAgentStories(agentId);
    } catch (e) {
      _log.severe('Failed to get agent stories $agentId: $e');
      rethrow;
    }
  }

  /// Mark a story as viewed
  Future<void> viewStory(String storyId) async {
    try {
      await _api.viewStory(storyId);
    } catch (e) {
      _log.warning('Failed to mark story as viewed: $e');
      // Non-critical, don't rethrow
    }
  }

  // ===========================================================================
  // UTILITIES
  // ===========================================================================

  /// Clear all caches
  void clearCache() {
    _cachedAgents = [];
    _agentsCacheTime = null;
  }
}
