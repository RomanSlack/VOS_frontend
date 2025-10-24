import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:vos_app/core/models/voice_models.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/api/voice_api.dart';

/// Connection state for voice WebSocket
enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Voice service for real-time voice interaction
/// Handles WebSocket connection, audio recording, and audio playback
class VoiceService {
  // API client
  late final Dio _dio;
  late final VoiceApi _voiceApi;

  // JWT Authentication
  String? _currentToken;
  DateTime? _tokenExpiry;
  Timer? _tokenRefreshTimer;

  // WebSocket
  WebSocketChannel? _channel;
  VoiceConnectionState _connectionState = VoiceConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  String? _currentSessionId;
  StreamSubscription? _messageSubscription;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordingSubscription;
  bool _isRecording = false;

  // Audio playback
  final AudioPlayer _player = AudioPlayer();

  VoiceService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ));

    // Debug logging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    _voiceApi = VoiceApi(_dio, baseUrl: AppConfig.apiBaseUrl);
  }

  // Stream controllers for broadcasting events
  final _connectionStateController =
      StreamController<VoiceConnectionState>.broadcast();
  final _voiceStateController = StreamController<VoiceState>.broadcast();
  final _sessionStartedController =
      StreamController<SessionStartedPayload>.broadcast();
  final _listeningStartedController =
      StreamController<ListeningStartedPayload>.broadcast();
  final _transcriptionInterimController =
      StreamController<TranscriptionPayload>.broadcast();
  final _transcriptionFinalController =
      StreamController<TranscriptionPayload>.broadcast();
  final _agentThinkingController =
      StreamController<AgentThinkingPayload>.broadcast();
  final _speakingStartedController =
      StreamController<SpeakingStartedPayload>.broadcast();
  final _speakingCompletedController =
      StreamController<SpeakingCompletedPayload>.broadcast();
  final _errorController = StreamController<VoiceErrorPayload>.broadcast();
  final _audioReceivedController =
      StreamController<AudioReceivedPayload>.broadcast();

  // Public stream getters
  Stream<VoiceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<VoiceState> get voiceStateStream => _voiceStateController.stream;
  Stream<SessionStartedPayload> get sessionStartedStream =>
      _sessionStartedController.stream;
  Stream<ListeningStartedPayload> get listeningStartedStream =>
      _listeningStartedController.stream;
  Stream<TranscriptionPayload> get transcriptionInterimStream =>
      _transcriptionInterimController.stream;
  Stream<TranscriptionPayload> get transcriptionFinalStream =>
      _transcriptionFinalController.stream;
  Stream<AgentThinkingPayload> get agentThinkingStream =>
      _agentThinkingController.stream;
  Stream<SpeakingStartedPayload> get speakingStartedStream =>
      _speakingStartedController.stream;
  Stream<SpeakingCompletedPayload> get speakingCompletedStream =>
      _speakingCompletedController.stream;
  Stream<VoiceErrorPayload> get errorStream => _errorController.stream;
  Stream<AudioReceivedPayload> get audioReceivedStream =>
      _audioReceivedController.stream;

  // Public state getters
  VoiceConnectionState get connectionState => _connectionState;
  bool get isRecording => _isRecording;

  /// Connect to voice WebSocket for a specific session
  Future<void> connect(String sessionId) async {
    if (_connectionState == VoiceConnectionState.connected &&
        _currentSessionId == sessionId) {
      debugPrint('🎙️ Already connected to voice session: $sessionId');
      return;
    }

    await disconnect();
    _currentSessionId = sessionId;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_currentSessionId == null) return;

    try {
      _updateConnectionState(VoiceConnectionState.connecting);

      // Step 1: Get JWT token from backend
      debugPrint('🔐 Requesting JWT token for session: $_currentSessionId');
      final tokenResponse = await _getVoiceToken(_currentSessionId!);

      _currentToken = tokenResponse.token;
      _tokenExpiry = DateTime.now().add(
        Duration(minutes: tokenResponse.expiresInMinutes),
      );

      debugPrint('✅ Received JWT token (expires in ${tokenResponse.expiresInMinutes} minutes)');

      // Schedule token refresh 5 minutes before expiry
      _scheduleTokenRefresh();

      // Step 2: Build voice WebSocket URL with token as query parameter
      final wsUrl = AppConfig.getVoiceWebSocketUrl(_currentSessionId!);
      final uri = Uri.parse('$wsUrl?token=$_currentToken');

      debugPrint('🎙️ Connecting to voice WebSocket: ${uri.replace(queryParameters: {'token': '[REDACTED]'})}');

      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _updateConnectionState(VoiceConnectionState.connected);
      _reconnectAttempts = 0;

      debugPrint('✅ Connected to voice WebSocket');

      // Send start_session message
      await _sendStartSession();
    } on DioException catch (e) {
      debugPrint('❌ Failed to get voice token: ${e.response?.statusCode} ${e.message}');
      _handleAuthError('Failed to authenticate: ${e.response?.data ?? e.message}');
      _updateConnectionState(VoiceConnectionState.disconnected);
    } catch (e) {
      debugPrint('❌ Voice WebSocket connection error: $e');
      _updateConnectionState(VoiceConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Request JWT token from backend
  Future<VoiceTokenResponse> _getVoiceToken(String sessionId) async {
    return await _voiceApi.getVoiceToken(sessionId);
  }

  /// Schedule token refresh 5 minutes before expiry
  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();

    if (_tokenExpiry == null) return;

    // Refresh token 5 minutes before it expires
    final refreshTime = _tokenExpiry!.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());

    if (delay.isNegative) {
      debugPrint('⚠️ Token already expired or expiring soon');
      return;
    }

    debugPrint('⏰ Token refresh scheduled in ${delay.inMinutes} minutes');

    _tokenRefreshTimer = Timer(delay, () async {
      debugPrint('🔄 Refreshing JWT token...');
      await _refreshToken();
    });
  }

  /// Refresh JWT token and reconnect
  Future<void> _refreshToken() async {
    if (_currentSessionId == null) return;

    try {
      // Get new token
      final tokenResponse = await _getVoiceToken(_currentSessionId!);

      _currentToken = tokenResponse.token;
      _tokenExpiry = DateTime.now().add(
        Duration(minutes: tokenResponse.expiresInMinutes),
      );

      debugPrint('✅ Token refreshed successfully');

      // Reconnect with new token
      await disconnect();
      await _establishConnection();

      // Schedule next refresh
      _scheduleTokenRefresh();
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      _handleAuthError('Failed to refresh authentication token');
    }
  }

  /// Handle authentication errors
  void _handleAuthError(String message) {
    debugPrint('🚫 Auth error: $message');
    _errorController.add(VoiceErrorPayload(
      code: 'authentication_failed',
      message: message,
      severity: 'error',
    ));
    _voiceStateController.add(VoiceState.error);
  }

  /// Send start_session message to server
  Future<void> _sendStartSession() async {
    final payload = StartSessionPayload.webDefault;
    final message = {
      'type': 'start_session',
      'payload': payload.toJson(),
    };

    _sendJsonMessage(message);
    debugPrint('🎙️ Sent start_session message');
  }

  /// Send end_session message to server
  Future<void> _sendEndSession() async {
    final message = {
      'type': 'end_session',
      'payload': {},
    };

    _sendJsonMessage(message);
    debugPrint('🎙️ Sent end_session message');
  }

  /// Send JSON message through WebSocket
  void _sendJsonMessage(Map<String, dynamic> message) {
    if (_connectionState == VoiceConnectionState.connected &&
        _channel != null) {
      _channel!.sink.add(json.encode(message));
    } else {
      debugPrint('⚠️ Cannot send message: WebSocket not connected');
    }
  }

  /// Send binary audio chunk through WebSocket
  void _sendAudioChunk(Uint8List chunk) {
    if (_connectionState == VoiceConnectionState.connected &&
        _channel != null) {
      _channel!.sink.add(chunk);
      debugPrint('🎤 Sent audio chunk: ${chunk.length} bytes');
    } else {
      debugPrint('⚠️ Cannot send audio: WebSocket not connected');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      // Check if binary data (TTS audio)
      if (data is Uint8List) {
        debugPrint('🔊 Received TTS audio: ${data.length} bytes');
        _playAudio(data);
        return;
      }

      // Parse JSON message
      final jsonData = json.decode(data as String) as Map<String, dynamic>;

      // Backend can send two formats:
      // 1. {"type": "status", "event": "...", "payload": {...}}
      // 2. {"type": "session_started", "payload": {...}}
      final messageType = jsonData['type'] as String?;
      final event = jsonData['event'] as String?;
      final payload = jsonData['payload'] as Map<String, dynamic>?;

      if (messageType == 'status' && event != null && payload != null) {
        debugPrint('📨 Received status event: $event');
        _handleStatusEvent(event, payload);
      } else if (messageType != null && payload != null) {
        // Direct event type (e.g., "session_started", "error")
        debugPrint('📨 Received event: $messageType');
        _handleStatusEvent(messageType, payload);
      } else {
        debugPrint('⚠️ Unknown message format: $jsonData');
      }
    } catch (e) {
      debugPrint('Error parsing voice message: $e');
    }
  }

  /// Handle status events from backend
  void _handleStatusEvent(String event, Map<String, dynamic> payload) {
    try {
      switch (event) {
        case 'session_started':
          final data = SessionStartedPayload.fromJson(payload);
          _sessionStartedController.add(data);
          _voiceStateController.add(VoiceState.idle);
          debugPrint('🎙️ Session started: ${data.sessionId}');
          break;

        case 'listening_started':
          final data = ListeningStartedPayload.fromJson(payload);
          _listeningStartedController.add(data);
          _voiceStateController.add(VoiceState.listening);
          debugPrint('👂 Listening started');
          break;

        case 'transcription_interim':
          final data = TranscriptionPayload.fromJson(payload);
          _transcriptionInterimController.add(data);
          debugPrint('📝 Interim transcription: ${data.text}');
          break;

        case 'transcription_final':
          final data = TranscriptionPayload.fromJson(payload);
          _transcriptionFinalController.add(data);
          debugPrint('✅ Final transcription: ${data.text}');
          break;

        case 'agent_thinking':
          final data = AgentThinkingPayload.fromJson(payload);
          _agentThinkingController.add(data);
          _voiceStateController.add(VoiceState.processing);
          debugPrint('🤔 Agent thinking: ${data.status}');
          break;

        case 'speaking_started':
          final data = SpeakingStartedPayload.fromJson(payload);
          _speakingStartedController.add(data);
          _voiceStateController.add(VoiceState.speaking);
          debugPrint(
              '🗣️ Speaking started: ${data.text} (${data.estimatedDurationMs}ms)');
          break;

        case 'speaking_completed':
          final data = SpeakingCompletedPayload.fromJson(payload);
          _speakingCompletedController.add(data);
          _voiceStateController.add(VoiceState.idle);
          debugPrint('✅ Speaking completed');

          // Emit audio URL for message attachment (for replay functionality)
          if (data.audioUrl != null) {
            // Build full URL from relative path (backend returns /api/v1/audio/signed/...)
            final fullAudioUrl = '${AppConfig.apiBaseUrl}${data.audioUrl}';
            debugPrint('💾 Audio URL: $fullAudioUrl');
            _audioReceivedController.add(AudioReceivedPayload(
              audioUrl: fullAudioUrl,
              durationMs: data.audioDurationMs,
              timestamp: data.timestamp,
            ));
          }
          break;

        case 'error':
          final data = VoiceErrorPayload.fromJson(payload);
          _errorController.add(data);
          _voiceStateController.add(VoiceState.error);
          debugPrint('❌ Voice error: ${data.message}');
          break;

        default:
          debugPrint('Unknown status event: $event');
      }
    } catch (e) {
      debugPrint('Error handling status event $event: $e');
    }
  }

  /// Start recording audio and streaming to server
  Future<void> startListening() async {
    if (_isRecording) {
      debugPrint('⚠️ Already recording');
      return;
    }

    try {
      // Check microphone permission
      if (await _recorder.hasPermission()) {
        // Configure recording settings for web (PCM 16-bit)
        final config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );

        // Start streaming
        final stream = await _recorder.startStream(config);

        _isRecording = true;
        _voiceStateController.add(VoiceState.listening);

        debugPrint('🎤 Started recording audio');

        // Stream audio chunks to WebSocket
        _recordingSubscription = stream.listen(
          (chunk) {
            _sendAudioChunk(chunk);
          },
          onError: (error) {
            debugPrint('❌ Recording error: $error');
            stopListening();
          },
          onDone: () {
            debugPrint('🎤 Recording stream done');
          },
        );
      } else {
        debugPrint('❌ Microphone permission denied');
        _errorController.add(const VoiceErrorPayload(
          code: 'permission_denied',
          message: 'Microphone permission is required',
          severity: 'error',
        ));
      }
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      _errorController.add(VoiceErrorPayload(
        code: 'recording_failed',
        message: 'Failed to start recording: $e',
        severity: 'error',
      ));
    }
  }

  /// Stop recording audio
  Future<void> stopListening() async {
    if (!_isRecording) return;

    try {
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;

      await _recorder.stop();
      _isRecording = false;
      _voiceStateController.add(VoiceState.idle);

      debugPrint('🎤 Stopped recording audio');
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
    }
  }

  /// Play TTS audio received from server
  Future<void> _playAudio(Uint8List audioData) async {
    try {
      String audioPath;

      if (kIsWeb) {
        // Web: Play directly from bytes using just_audio's setAudioSource
        // just_audio on web can handle bytes directly
        audioPath = 'blob:audio_${DateTime.now().millisecondsSinceEpoch}';

        debugPrint('🔊 Playing TTS audio on web (${audioData.length} bytes)');

        // Use just_audio's built-in support for web audio
        await _player.setAudioSource(
          _BytesAudioSource(audioData),
        );
        await _player.play();
      } else {
        // Mobile: Save to temp file and play
        final audioFile = await _saveAudio(audioData);
        audioPath = audioFile.path;

        debugPrint('🔊 Playing TTS audio (${audioData.length} bytes)');
        debugPrint('💾 Audio saved to: ${audioFile.path}');

        await _player.setFilePath(audioFile.path);
        await _player.play();
      }

      // Audio URL will be emitted when speaking_completed event arrives

      // Listen for playback completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          debugPrint('✅ Audio playback completed');
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to play audio: $e');
      _errorController.add(VoiceErrorPayload(
        code: 'playback_failed',
        message: 'Failed to play audio: $e',
        severity: 'error',
      ));
    }
  }

  /// Save audio data to file (mobile only)
  Future<File> _saveAudio(Uint8List audioData) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioFile = File('${tempDir.path}/tts_audio_$timestamp.mp3');
    await audioFile.writeAsBytes(audioData);
    return audioFile;
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    debugPrint('❌ Voice WebSocket error: $error');

    // Check for authentication-related WebSocket close codes
    final errorString = error.toString();

    if (errorString.contains('1008')) {
      // Code 1008: Token invalid, expired, or session ID mismatch
      debugPrint('🚫 WebSocket closed: Token invalid or expired (code 1008)');
      _handleAuthError('Session token expired or invalid. Please try again.');
      _updateConnectionState(VoiceConnectionState.disconnected);
      // Do not auto-reconnect for auth errors - user needs to restart session
      return;
    }

    if (errorString.contains('1011')) {
      // Code 1011: Authentication failed
      debugPrint('🚫 WebSocket closed: Authentication failed (code 1011)');
      _handleAuthError('Authentication failed. Please check your credentials.');
      _updateConnectionState(VoiceConnectionState.disconnected);
      // Do not auto-reconnect for auth errors
      return;
    }

    // For other errors, attempt reconnection
    _updateConnectionState(VoiceConnectionState.disconnected);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    debugPrint('🔌 Voice WebSocket disconnected');

    // Check if token is about to expire
    if (_tokenExpiry != null) {
      final timeUntilExpiry = _tokenExpiry!.difference(DateTime.now());

      if (timeUntilExpiry.isNegative) {
        debugPrint('⏰ Token has expired');
        _handleAuthError('Session token expired. Please restart voice session.');
        _updateConnectionState(VoiceConnectionState.disconnected);
        return;
      }

      if (timeUntilExpiry.inMinutes < 5) {
        debugPrint('⚠️ Token expiring soon (${timeUntilExpiry.inMinutes} minutes)');
      }
    }

    if (_connectionState != VoiceConnectionState.disconnected) {
      _updateConnectionState(VoiceConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached. Please refresh.');
      return;
    }

    if (_reconnectTimer?.isActive ?? false) return;

    final delay = _getReconnectDelay();
    _reconnectAttempts++;

    debugPrint(
      '🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...',
    );

    _updateConnectionState(VoiceConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      _establishConnection();
    });
  }

  /// Calculate reconnection delay with exponential backoff
  Duration _getReconnectDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, ... up to 30s
    final exponent = (_reconnectAttempts - 1).clamp(0, 10);
    final delay = (1000 * (1 << exponent)).clamp(1000, 30000);
    return Duration(milliseconds: delay);
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(VoiceConnectionState newState) {
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  /// Disconnect from voice WebSocket
  Future<void> disconnect() async {
    debugPrint('🎙️ Disconnecting voice WebSocket...');

    // Stop recording if active
    await stopListening();

    // Stop playback if active
    await _player.stop();

    // Send end_session message before disconnecting
    if (_connectionState == VoiceConnectionState.connected) {
      await _sendEndSession();
      // Give some time for message to be sent
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Cancel reconnection timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Cancel token refresh timer
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;

    // Clear token
    _currentToken = null;
    _tokenExpiry = null;

    // Close WebSocket
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _currentSessionId = null;
    _reconnectAttempts = 0;

    _updateConnectionState(VoiceConnectionState.disconnected);
    _voiceStateController.add(VoiceState.idle);
  }

  /// Dispose and clean up all resources
  Future<void> dispose() async {
    await disconnect();
    await _recorder.dispose();
    await _player.dispose();

    _connectionStateController.close();
    _voiceStateController.close();
    _sessionStartedController.close();
    _listeningStartedController.close();
    _transcriptionInterimController.close();
    _transcriptionFinalController.close();
    _agentThinkingController.close();
    _speakingStartedController.close();
    _speakingCompletedController.close();
    _audioReceivedController.close();
    _errorController.close();
  }
}

/// Custom audio source for playing audio from bytes on web
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  _BytesAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
