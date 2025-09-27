import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/chat_api.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/chat_manager.dart';

class ChatService {
  late final ChatApi _chatApi;
  late final Dio _dio;

  ChatService() {
    _dio = Dio();

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
      // Convert ChatMessage to ChatMessageDto
      final dtoMessages = messages.map((msg) => ChatMessageDto(
        role: msg.isUser ? 'user' : 'assistant',
        content: msg.text,
      )).toList();

      final request = ChatRequestDto(
        messages: dtoMessages,
        model: 'gpt-3.5-turbo',
        maxTokens: 1000,
        temperature: 0.7,
      );

      final response = await _chatApi.chatCompletions(request);
      return response.message;

    } on DioException catch (e) {
      debugPrint('Chat API Error: ${e.message}');
      if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please check if the API server is running and configured properly.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to chat server. Please ensure the server is running on localhost:5555');
      }
      throw Exception('Chat request failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

}