import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vos_app/core/api/chat_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/models/chat_models.dart';

class SessionService {
  static const String _sessionIdKey = 'current_session_id';

  // Singleton pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;

  late final ChatApi _chatApi;
  late final Dio _dio;
  String? _cachedSessionId;

  SessionService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ));

    // JWT authentication only (no API key - security fix)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }
          // Note: Session service calls may happen before login,
          // so JWT may not always be available
          return handler.next(options);
        },
      ),
    );

    _chatApi = ChatApi(_dio, baseUrl: AppConfig.apiBaseUrl);
  }

  /// Get the current session ID
  Future<String> getSessionId() async {
    if (_cachedSessionId != null) {
      return _cachedSessionId!;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionIdKey);

    if (sessionId != null && sessionId.isNotEmpty) {
      _cachedSessionId = sessionId;
      return sessionId;
    }

    // Generate a new session ID if none exists
    final newSessionId = generateSessionName();
    await setSessionId(newSessionId);
    return newSessionId;
  }

  /// Set the current session ID
  Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
    _cachedSessionId = sessionId;
    debugPrint('Session ID set to: $sessionId');
  }

  /// Clear the session ID (for logout)
  Future<void> clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    _cachedSessionId = null;
  }

  /// Generate a unique session name
  String generateSessionName() {
    const uuid = Uuid();
    final shortId = uuid.v4().substring(0, 8);
    return 'session-$shortId';
  }

  /// Check if a session name already exists
  Future<bool> sessionExists(String sessionId) async {
    try {
      final sessions = await listSessions();
      return sessions.any((s) => s.sessionId == sessionId);
    } catch (e) {
      debugPrint('Error checking session existence: $e');
      return false;
    }
  }

  /// Generate a unique session name that doesn't exist yet
  Future<String> generateUniqueSessionName() async {
    String sessionName = generateSessionName();

    // Check if it exists and regenerate if needed
    int attempts = 0;
    while (await sessionExists(sessionName) && attempts < 10) {
      sessionName = generateSessionName();
      attempts++;
    }

    return sessionName;
  }

  /// List all existing sessions
  Future<List<SessionInfoDto>> listSessions() async {
    try {
      final response = await _chatApi.listSessions(limit: 100);
      return response.sessions;
    } on DioException catch (e) {
      debugPrint('Error listing sessions: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed');
      }
      throw Exception('Failed to list sessions: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error listing sessions: $e');
      throw Exception('Failed to list sessions: $e');
    }
  }
}
