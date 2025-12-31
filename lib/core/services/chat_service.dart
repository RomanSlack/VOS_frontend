import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/chat_api.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/models/document_models.dart';
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/websocket_service.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/core/services/document_service.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/utils/timezone_helper.dart';

class ChatService {
  late final ChatApi _chatApi;
  late final Dio _dio;
  late final WebSocketService _webSocketService;
  final SessionService _sessionService = SessionService();

  static const String _agentId = 'primary_agent';

  // Keep polling as fallback
  static const int _maxPollingAttempts = 30;
  static const Duration _pollingInterval = Duration(seconds: 1);

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _actionSubscription;
  bool _useWebSocket = true; // Toggle to enable/disable WebSocket

  ChatService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ));

    // Add API key authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = AppConfig.apiKey;
          // For Android emulator, override Host header to localhost
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }
          return handler.next(options);
        },
      ),
    );

    // Logging disabled for performance - re-enable only when debugging specific issues
    // if (kDebugMode) {
    //   _dio.interceptors.add(LogInterceptor(
    //     requestBody: false,  // Disable body logging for performance
    //     responseBody: false,
    //     logPrint: (obj) => debugPrint(obj.toString()),
    //   ));
    // }

    _chatApi = ChatApi(_dio, baseUrl: AppConfig.apiBaseUrl);
    // Use shared WebSocketService from DI container
    _webSocketService = getIt<WebSocketService>();
  }

  /// Initialize WebSocket connection for a session
  Future<void> initializeWebSocket({String? sessionId, ChatManager? chatManager}) async {
    if (!_useWebSocket) return;

    // Get session from SessionService if not provided
    final session = sessionId ?? await _sessionService.getSessionId();

    try {
      // Get JWT token from auth service
      final authService = AuthService();
      final token = await authService.getToken();

      await _webSocketService.connect(session, jwtToken: token);

      // Subscribe to message stream if chatManager is provided
      if (chatManager != null) {
        _messageSubscription?.cancel();
        _messageSubscription = _webSocketService.messageStream.listen(
          (payload) async {
            // Verbose logging disabled for performance
            // debugPrint('📦 WebSocket payload received:');
            // debugPrint('  - sessionId: ${payload.sessionId}');
            // debugPrint('  - agentId: ${payload.agentId}');
            // debugPrint('  - messageId: ${payload.messageId}');
            // debugPrint('  - inputMode: ${payload.inputMode}');
            // debugPrint('  - voiceMessageId: ${payload.voiceMessageId}');
            // debugPrint('  - audioUrl: ${payload.audioUrl}');
            // debugPrint('  - audioDurationMs: ${payload.audioDurationMs}');

            // Parse the content to extract actual message
            final actualMessage = _parseMessageContent(payload.content);

            // Build full audio URL if provided (backend returns relative path)
            String? fullAudioUrl;
            if (payload.audioUrl != null) {
              fullAudioUrl = '${AppConfig.apiBaseUrl}${payload.audioUrl}';
              debugPrint('🎵 Message includes audio: $fullAudioUrl');
            } else {
              debugPrint('⚠️ No audio URL in payload');
            }

            // Fetch attachment metadata if agent sent images
            List<ChatAttachment>? attachments;
            if (payload.attachmentIds != null && payload.attachmentIds!.isNotEmpty) {
              debugPrint('🖼️ Agent sent ${payload.attachmentIds!.length} attachments');
              attachments = await _fetchAttachmentsMetadata(payload.attachmentIds!);
            }

            // Fetch document metadata if agent sent documents
            List<Document>? documents;
            if (payload.documentIds != null && payload.documentIds!.isNotEmpty) {
              debugPrint('📄 Agent sent ${payload.documentIds!.length} documents');
              documents = await _fetchDocumentsMetadata(payload.documentIds!);
            }

            // Add agent message to chat with audio, attachment, and document metadata
            chatManager.addMessage(
              actualMessage,
              false,
              inputMode: payload.inputMode ?? 'text',
              voiceMessageId: payload.voiceMessageId,
              audioFilePath: fullAudioUrl,
              audioDurationMs: payload.audioDurationMs,
              attachments: attachments,
              documents: documents,
            );
            debugPrint('💬 Added message from ${payload.agentId}');
          },
          onError: (error) {
            debugPrint('Error in message stream: $error');
          },
        );

        // Subscribe to status updates
        _statusSubscription?.cancel();
        _statusSubscription = _webSocketService.statusStream.listen(
          (payload) {
            // Handle status updates (thinking, executing, etc.)
            debugPrint('📊 Status: ${payload.processingState ?? payload.status}');
            // Update ChatManager with agent status
            chatManager.updateAgentState(
              payload.processingState,
              null, // No action description in this notification
            );
          },
          onError: (error) {
            debugPrint('Error in status stream: $error');
          },
        );

        // Subscribe to agent action status updates
        _actionSubscription?.cancel();
        _actionSubscription = _webSocketService.actionStream.listen(
          (payload) {
            // Handle action descriptions (e.g., "Searching weather data...")
            debugPrint('💭 Action: ${payload.actionDescription}');
            // Update ChatManager with action description
            chatManager.updateAgentState(
              null, // No processing state in this notification
              payload.actionDescription,
            );
          },
          onError: (error) {
            debugPrint('Error in action stream: $error');
          },
        );
      }

      debugPrint('✅ WebSocket initialized for session: $session');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize WebSocket: $e');
      debugPrint('Falling back to polling mode');
      _useWebSocket = false;
    }
  }

  /// Get WebSocket connection state
  WebSocketConnectionState get connectionState => _webSocketService.state;

  /// Get WebSocket state stream for UI updates
  Stream<WebSocketConnectionState> get stateStream => _webSocketService.stateStream;

  /// Get WebSocket message stream for UI updates
  Stream<NewMessagePayload> get messageStream => _webSocketService.messageStream;

  /// Get WebSocket status stream for UI updates
  Stream<AgentStatusPayload> get statusStream => _webSocketService.statusStream;

  /// Get WebSocket action stream for UI updates
  Stream<AgentActionStatusPayload> get actionStream => _webSocketService.actionStream;

  /// Get WebSocket app interaction stream for UI updates
  Stream<AppInteractionPayload> get appInteractionStream => _webSocketService.appInteractionStream;

  Stream<BrowserScreenshotPayload> get browserScreenshotStream => _webSocketService.browserScreenshotStream;

  /// Get user's timezone (IANA timezone name)
  /// Returns timezone string like "America/New_York" or null if unavailable
  String? _getUserTimezone() {
    return TimezoneHelper.getUserTimezone();
  }

  /// Parse message content to extract actual user-facing message
  /// Handles raw agent responses with thought/tool_calls structure
  String _parseMessageContent(String content) {
    try {
      // Try to parse as JSON
      final jsonData = json.decode(content);

      // Check if it's a raw agent response with tool_calls
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('tool_calls')) {
        final toolCalls = jsonData['tool_calls'] as List<dynamic>;

        // Find send_user_message tool call
        for (final toolCall in toolCalls) {
          if (toolCall is Map<String, dynamic> &&
              toolCall['tool_name'] == 'send_user_message') {
            final arguments = toolCall['arguments'] as Map<String, dynamic>?;
            if (arguments != null && arguments.containsKey('content')) {
              return arguments['content'] as String;
            }
          }
        }
      }

      // If we couldn't extract, return original content
      return content;
    } catch (e) {
      // If not valid JSON, return as-is
      debugPrint('Could not parse message content as JSON: $e');
      return content;
    }
  }

  /// Fetch attachment metadata for given attachment IDs
  /// Returns list of ChatAttachment objects with signed URLs
  Future<List<ChatAttachment>> _fetchAttachmentsMetadata(List<String> attachmentIds) async {
    final attachments = <ChatAttachment>[];

    for (final attachmentId in attachmentIds) {
      try {
        // Fetch metadata
        final metadataResponse = await _dio.get('/api/v1/attachments/$attachmentId');
        final metadata = metadataResponse.data as Map<String, dynamic>;

        // Fetch signed URL
        final urlResponse = await _dio.get('/api/v1/attachments/$attachmentId/url');
        final urlData = urlResponse.data as Map<String, dynamic>;
        final signedUrl = urlData['url'] as String?;

        // Build full URL
        String? fullUrl;
        if (signedUrl != null) {
          fullUrl = signedUrl.startsWith('http')
              ? signedUrl
              : '${AppConfig.apiBaseUrl}$signedUrl';
        }

        attachments.add(ChatAttachment(
          attachmentId: attachmentId,
          url: fullUrl,
          fileName: metadata['original_filename'] as String? ?? 'attachment',
          contentType: metadata['content_type'] as String? ?? 'image/png',
          width: metadata['width'] as int?,
          height: metadata['height'] as int?,
        ));

        debugPrint('📎 Loaded attachment: $attachmentId');
      } catch (e) {
        debugPrint('⚠️ Failed to load attachment $attachmentId: $e');
        // Still add a placeholder attachment so the message knows it had images
        attachments.add(ChatAttachment(
          attachmentId: attachmentId,
          fileName: 'attachment',
          contentType: 'image/unknown',
        ));
      }
    }

    return attachments;
  }

  /// Fetch documents for given document IDs
  /// Returns list of Document objects
  Future<List<Document>> _fetchDocumentsMetadata(List<String> documentIds) async {
    final documents = <Document>[];
    final documentService = getIt<DocumentService>();

    for (final documentId in documentIds) {
      try {
        final document = await documentService.getDocument(documentId);
        if (document != null) {
          documents.add(document);
          debugPrint('📄 Loaded document: $documentId');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load document $documentId: $e');
      }
    }

    return documents;
  }

  /// Load conversation history from the backend
  Future<List<ChatMessage>> loadConversationHistory({String? sessionId}) async {
    try {
      final session = sessionId ?? await _sessionService.getSessionId();

      // Get conversation from the conversations API (not transcript API)
      final conversation = await _chatApi.getConversationHistory(session, limit: 500);

      final messages = <ChatMessage>[];

      // Convert conversation messages to ChatMessage objects
      for (final msg in conversation.messages) {
        // Determine if message is from user
        final isUser = msg.senderType == 'user';

        // Content is already a plain string in conversation_messages
        final messageText = msg.content;

        // Skip empty messages
        if (messageText.trim().isEmpty) continue;

        // Parse timestamp
        DateTime timestamp;
        try {
          timestamp = DateTime.parse(msg.timestamp);
        } catch (e) {
          timestamp = DateTime.now();
        }

        // Build full audio URL if available (backend returns relative path)
        String? fullAudioUrl;
        if (msg.audioUrl != null) {
          fullAudioUrl = '${AppConfig.apiBaseUrl}${msg.audioUrl}';
        }

        // Fetch attachments if message has attachment_ids
        // Check both direct field and metadata (backend stores in metadata.attachment_ids)
        List<ChatAttachment>? attachments;
        List<String>? attachmentIds = msg.attachmentIds;

        // Fallback: extract from metadata if direct field is empty
        if ((attachmentIds == null || attachmentIds.isEmpty) && msg.metadata != null) {
          final metadataIds = msg.metadata!['attachment_ids'];
          if (metadataIds is List && metadataIds.isNotEmpty) {
            attachmentIds = metadataIds.cast<String>();
          }
        }

        if (attachmentIds != null && attachmentIds.isNotEmpty) {
          attachments = await _fetchAttachmentsMetadata(attachmentIds);
        }

        // Fetch documents if message has document_ids
        // Check both direct field and metadata (backend stores in metadata.document_ids)
        List<Document>? documents;
        List<String>? documentIds = msg.documentIds;

        debugPrint('📋 Message: documentIds=$documentIds, metadata=${msg.metadata}');

        // Fallback: extract from metadata if direct field is empty
        if ((documentIds == null || documentIds.isEmpty) && msg.metadata != null) {
          final metadataIds = msg.metadata!['document_ids'];
          debugPrint('📋 Checking metadata for document_ids: $metadataIds');
          if (metadataIds is List && metadataIds.isNotEmpty) {
            documentIds = metadataIds.cast<String>();
            debugPrint('📋 Extracted document_ids from metadata: $documentIds');
          }
        }

        if (documentIds != null && documentIds.isNotEmpty) {
          debugPrint('📄 Fetching ${documentIds.length} documents for message');
          documents = await _fetchDocumentsMetadata(documentIds);
          debugPrint('📄 Loaded ${documents.length} documents');
        }

        messages.add(ChatMessage(
          text: messageText,
          isUser: isUser,
          timestamp: timestamp,
          inputMode: msg.inputMode ?? 'text',
          voiceMessageId: msg.voiceMessageId,
          audioFilePath: fullAudioUrl, // Store full URL for playback
          audioDurationMs: msg.audioDurationMs,
          attachments: attachments,
          documents: documents,
        ));
      }

      debugPrint('📜 Loaded ${messages.length} conversation messages from session $session');
      return messages;

    } on DioException catch (e) {
      debugPrint('Error loading conversation history: ${e.message}');
      throw Exception('Failed to load conversation history: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error loading history: $e');
      throw Exception('Failed to load conversation history: $e');
    }
  }

  Future<String> getChatCompletion(List<ChatMessage> messages) async {
    try {
      // Extract the last user message
      final userMessages = messages.where((m) => m.isUser).toList();
      if (userMessages.isEmpty) {
        throw Exception('No user message to send');
      }

      final lastMessage = userMessages.last;
      final lastUserMessage = lastMessage.text;

      // Extract attachment IDs if present
      List<String>? attachmentIds;
      if (lastMessage.hasAttachments) {
        attachmentIds = lastMessage.attachments!
            .map((a) => a.attachmentId)
            .toList();
        debugPrint('📎 Sending message with ${attachmentIds.length} attachments');
      }

      // Get user's timezone for calendar operations
      final userTimezone = _getUserTimezone();
      debugPrint('User timezone: $userTimezone');

      // Get session ID
      final sessionId = await _sessionService.getSessionId();

      // Send message to VOS (this already stores in conversation_messages)
      final request = VosMessageRequestDto(
        text: lastUserMessage,
        sessionId: sessionId,
        userTimezone: userTimezone,
        attachmentIds: attachmentIds,
      );
      final sendResponse = await _chatApi.sendMessage(request);

      debugPrint('Message sent: ${sendResponse.notificationId}');

      // If WebSocket is active, response will come through the stream
      // Return empty string as response will be handled by WebSocket listener
      if (_useWebSocket && _webSocketService.state == WebSocketConnectionState.connected) {
        debugPrint('✅ Using WebSocket for response');
        return ''; // Response will come via WebSocket stream
      }

      // Fallback to polling if WebSocket is not available
      debugPrint('⚠️ WebSocket not available, using polling');
      final transcriptBefore = await _chatApi.getTranscript(_agentId, limit: 500);
      final messageCountBefore = transcriptBefore.totalMessages;
      final response = await _pollForResponse(messageCountBefore);
      return response;

    } on DioException catch (e) {
      debugPrint('Chat API Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please check API key configuration.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please check if the VOS API server is running properly.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to VOS server at ${AppConfig.apiBaseUrl}');
      }
      throw Exception('Chat request failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String> _pollForResponse(int previousMessageCount) async {
    for (int attempt = 0; attempt < _maxPollingAttempts; attempt++) {
      await Future.delayed(_pollingInterval);

      try {
        final transcript = await _chatApi.getTranscript(_agentId, limit: 500);

        // Check if we have new messages
        if (transcript.totalMessages > previousMessageCount) {
          // Find the last assistant message
          final assistantMessages = transcript.messages
              .where((msg) => msg.role == 'assistant')
              .toList();

          if (assistantMessages.isNotEmpty) {
            final lastAssistantMessage = assistantMessages.last;
            return lastAssistantMessage.content.text;
          }
        }

        debugPrint('Polling attempt ${attempt + 1}/$_maxPollingAttempts...');

      } on DioException catch (e) {
        debugPrint('Polling error: ${e.message}');
        // Continue polling on errors unless it's a critical failure
        if (e.response?.statusCode == 401) {
          throw Exception('Authentication failed during polling');
        }
        // Otherwise, continue polling
      }
    }

    throw Exception('Response timeout: No response received after ${_maxPollingAttempts} seconds');
  }

  /// Delete conversation and all agent transcripts
  ///
  /// This deletes both:
  /// 1. The conversation messages (user-facing chat history)
  /// 2. All agents' transcripts (all agents' internal message histories)
  ///
  /// Returns true on success, throws exception on error
  Future<bool> deleteConversationAndTranscript({String? sessionId}) async {
    try {
      final session = sessionId ?? await _sessionService.getSessionId();

      debugPrint('🗑️ Deleting conversation and all agent transcripts...');

      // Delete conversation messages
      final conversationResult = await _chatApi.deleteConversation(session);
      debugPrint('✅ Conversation deleted: ${conversationResult['deleted_count']} messages');

      // Get all agents from the backend
      final agentsResponse = await _chatApi.getAllAgents();

      // Handle response - backend returns array directly, not wrapped in object
      final List<dynamic> agents = agentsResponse is List
          ? agentsResponse
          : (agentsResponse is Map && agentsResponse.containsKey('agents')
              ? agentsResponse['agents']
              : []);

      debugPrint('📋 Found ${agents.length} agents to delete transcripts for');

      // Delete transcript for each agent
      int totalDeletedMessages = 0;
      for (final agent in agents) {
        final agentId = agent['agent_id'] ?? agent['id'];
        if (agentId != null) {
          try {
            final transcriptResult = await _chatApi.deleteTranscript(
              agentId,
              resetSystemPrompt: true,
              clearNotifications: true,
            );
            final deletedCount = transcriptResult['deleted_messages'] ?? 0;
            totalDeletedMessages += deletedCount as int;
            debugPrint('✅ Deleted transcript for agent "$agentId": $deletedCount messages');
          } catch (e) {
            debugPrint('⚠️ Failed to delete transcript for agent "$agentId": $e');
            // Continue with other agents even if one fails
          }
        }
      }

      debugPrint('✅ All transcripts deleted: $totalDeletedMessages total messages');

      return true;

    } on DioException catch (e) {
      debugPrint('Error deleting conversation: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Unable to delete conversation.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Conversation not found.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error while deleting conversation.');
      }
      throw Exception('Failed to delete conversation: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error deleting conversation: $e');
      throw Exception('An unexpected error occurred while deleting: $e');
    }
  }

  /// Dispose and cleanup resources
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _actionSubscription?.cancel();
    _webSocketService.dispose();
  }
}