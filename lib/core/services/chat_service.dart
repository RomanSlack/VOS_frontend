import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/chat_api.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/chat_manager.dart';

class ChatService {
  late final ChatApi _chatApi;
  late final Dio _dio;

  static const String _apiKey = 'dev-key-12345';
  static const String _agentId = 'primary_agent';
  static const int _maxPollingAttempts = 30;
  static const Duration _pollingInterval = Duration(seconds: 1);

  ChatService() {
    _dio = Dio();

    // Add API key authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = _apiKey;
          return handler.next(options);
        },
      ),
    );

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    _chatApi = ChatApi(_dio);
  }

  Future<String> getChatCompletion(List<ChatMessage> messages) async {
    try {
      // Extract the last user message
      final userMessages = messages.where((m) => m.isUser).toList();
      if (userMessages.isEmpty) {
        throw Exception('No user message to send');
      }

      final lastUserMessage = userMessages.last.text;

      // Get current transcript message count before sending
      final transcriptBefore = await _chatApi.getTranscript(_agentId, limit: 500);
      final messageCountBefore = transcriptBefore.totalMessages;

      // Send message to VOS
      final request = VosMessageRequestDto(text: lastUserMessage);
      final sendResponse = await _chatApi.sendMessage(request);

      debugPrint('Message sent: ${sendResponse.notificationId}');

      // Poll for response
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
        throw Exception('Cannot connect to VOS server. Please ensure the server is running on localhost:8000');
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

}