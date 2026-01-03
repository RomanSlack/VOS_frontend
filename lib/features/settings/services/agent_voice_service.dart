import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/features/settings/models/agent_voice_model.dart';

/// Service for managing agent voice settings via API
class AgentVoiceService {
  final AuthService _authService;
  final String _baseUrl;

  AgentVoiceService({
    required AuthService authService,
    String? baseUrl,
  })  : _authService = authService,
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Get headers with authentication
  Map<String, String> get _headers {
    final token = _authService.apiKey;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'X-API-Key': token,
    };
  }

  /// Get user ID (session ID)
  String get _userId {
    return _authService.sessionId ?? 'default';
  }

  /// Get all default voices for agents
  Future<List<AgentDefaultVoice>> getDefaultVoices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/agent-voices/defaults'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => AgentDefaultVoice.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load default voices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching default voices: $e');
    }
  }

  /// Get effective voices for all agents (user preference or default)
  Future<List<AgentVoiceSetting>> getEffectiveVoices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/agent-voices/effective/$_userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => AgentVoiceSetting.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load effective voices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching effective voices: $e');
    }
  }

  /// Get effective voice for a specific agent
  Future<AgentVoiceSetting> getEffectiveVoice(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/agent-voices/effective/$_userId/$agentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return AgentVoiceSetting.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load voice for $agentId: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching voice for $agentId: $e');
    }
  }

  /// Set voice preference for an agent
  Future<AgentVoiceSetting> setAgentVoice({
    required String agentId,
    required String ttsProvider,
    required String voiceId,
    String? voiceName,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/agent-voices/user/$_userId/$agentId'),
        headers: _headers,
        body: json.encode({
          'agent_id': agentId,
          'tts_provider': ttsProvider,
          'voice_id': voiceId,
          'voice_name': voiceName,
        }),
      );

      if (response.statusCode == 200) {
        return AgentVoiceSetting.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to set voice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting voice: $e');
    }
  }

  /// Reset agent voice to default
  Future<void> resetAgentVoice(String agentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/agent-voices/user/$_userId/$agentId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception('Failed to reset voice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting voice: $e');
    }
  }

  /// Reset all agent voices to defaults
  Future<void> resetAllVoices() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/agent-voices/user/$_userId/all'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset all voices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting all voices: $e');
    }
  }
}
