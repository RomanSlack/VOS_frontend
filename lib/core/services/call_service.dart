import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/core/services/audio_player_manager.dart';

/// Call service for voice calls with VOS agents
///
/// Handles:
/// - WebSocket connection for call signaling
/// - Audio recording and streaming
/// - TTS playback
/// - Call state management
class CallService {
  // Auth service for token
  final AuthService _authService;

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordingSubscription;
  bool _isRecording = false;
  bool _isMuted = false;

  // Audio playback
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  final List<Uint8List> _audioQueue = [];
  bool _isPlaying = false;
  static const String _audioSourceId = 'call_audio';

  // Keepalive timer
  Timer? _keepaliveTimer;
  DateTime? _lastAudioSentTime;
  static const Duration _keepaliveInterval = Duration(milliseconds: 100);

  // Current state
  String? _currentSessionId;
  Call? _currentCall;
  CallState _callState = CallState.idle;

  // Audio type tracking for call vs chat audio
  String _pendingAudioType = 'call_speech';
  bool _shouldAutoPlayNextAudio = true;

  // Stream controllers
  final _callStateController = StreamController<CallState>.broadcast();
  final _callController = StreamController<Call?>.broadcast();
  final _transcriptController = StreamController<CallTranscript>.broadcast();
  final _agentSpeakingController = StreamController<bool>.broadcast();
  final _incomingCallController =
      StreamController<IncomingCallPayload>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Public streams
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<Call?> get callStream => _callController.stream;
  Stream<CallTranscript> get transcriptStream => _transcriptController.stream;
  Stream<bool> get agentSpeakingStream => _agentSpeakingController.stream;
  Stream<IncomingCallPayload> get incomingCallStream =>
      _incomingCallController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  // Public getters
  CallState get callState => _callState;
  Call? get currentCall => _currentCall;
  bool get isConnected => _channel != null;
  bool get isOnCall =>
      _callState == CallState.connected ||
      _callState == CallState.ringingOutbound ||
      _callState == CallState.ringingInbound;
  bool get isMuted => _isMuted;

  CallService(this._authService);

  // ===========================================================================
  // Connection Management
  // ===========================================================================

  /// Connect to call WebSocket for a session
  Future<bool> connect(String sessionId) async {
    if (_channel != null && _currentSessionId == sessionId) {
      debugPrint('Already connected to call WebSocket');
      return true;
    }

    await disconnect();
    _currentSessionId = sessionId;

    try {
      // Get JWT token
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No valid token for call WebSocket');
        return false;
      }

      // Build WebSocket URL (note: /api/v1 prefix required)
      final wsUrl = '${AppConfig.wsBaseUrl}/api/v1/ws/call/$sessionId?token=$token';
      debugPrint('Connecting to call WebSocket: $wsUrl');

      // Connect
      if (!kIsWeb && (AppConfig.apiBaseUrl.contains('10.0.2.2') || AppConfig.apiBaseUrl.contains('localhost'))) {
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          headers: {'Host': 'localhost:8000'},
          pingInterval: const Duration(seconds: 5),
        );
      } else {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      }

      // Listen to messages
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      debugPrint('Connected to call WebSocket');

      // Register audio player with global manager
      _audioManager.register(_audioSourceId, _player);

      return true;
    } catch (e) {
      debugPrint('Failed to connect to call WebSocket: $e');
      _connectionStateController.add(false);
      return false;
    }
  }

  /// Disconnect from call WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _keepaliveTimer?.cancel();

    await stopRecording();
    _clearAudioQueue();
    await _player.stop();

    // Unregister from global audio manager
    _audioManager.unregister(_audioSourceId);

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _currentSessionId = null;
    _currentCall = null;
    _updateCallState(CallState.idle);
    _connectionStateController.add(false);

    debugPrint('Disconnected from call WebSocket');
  }

  /// Interrupt any currently playing call audio.
  ///
  /// Call this when the user starts speaking to stop agent audio playback.
  Future<void> interruptAudio() async {
    debugPrint('Interrupting call audio');
    _clearAudioQueue();
    await _player.stop();
    _agentSpeakingController.add(false);
  }

  void _handleDisconnect() {
    debugPrint('Call WebSocket disconnected');
    _connectionStateController.add(false);

    // Clear the channel so next connect() creates a new one
    _channel = null;
    _messageSubscription = null;

    // If on hold, don't reconnect - it's intentional
    if (_callState == CallState.onHold) {
      return;
    }

    // If call was active, try to reconnect
    if (_callState == CallState.connected) {
      _scheduleReconnect();
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Call WebSocket error: $error');
    _errorController.add('Connection error: $error');
    _connectionStateController.add(false);

    // Clear the channel so next connect() creates a new one
    _channel = null;
    _messageSubscription = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _updateCallState(CallState.ended);
      return;
    }

    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
    _reconnectAttempts++;

    debugPrint('Reconnecting in ${delay.inSeconds}s...');

    _reconnectTimer = Timer(delay, () {
      if (_currentSessionId != null) {
        connect(_currentSessionId!);
      }
    });
  }

  // ===========================================================================
  // Call Actions
  // ===========================================================================

  /// Initiate a call to an agent
  ///
  /// [targetAgent] - The agent to call (default: primary_agent)
  /// [fastMode] - Enable fast mode for low-latency responses with limited tools
  Future<bool> initiateCall({
    String targetAgent = 'primary_agent',
    bool fastMode = false,
  }) async {
    if (_channel == null) {
      debugPrint('Not connected to WebSocket');
      _errorController.add('Not connected to server');
      return false;
    }

    // Force cleanup if we're in a weird state but the user wants to call
    if (_callState != CallState.idle && _callState != CallState.ended) {
      debugPrint('Warning: Attempting to call while state is $_callState. Forcing cleanup.');
      await endCall();
      // Give it a moment to reset
      await Future.delayed(const Duration(milliseconds: 200));

      if (_callState != CallState.idle && _callState != CallState.ended) {
         debugPrint('Still in call state after cleanup. Cannot initiate.');
         _errorController.add('Already in a call');
         return false;
      }
    }

    try {
      // Clear any previous call state to be safe
      _currentCall = null;
      _callController.add(null);

      _sendMessage({
        'type': 'initiate_call',
        'target_agent': targetAgent,
        'fast_mode': fastMode,
      });

      _updateCallState(CallState.ringingOutbound);
      debugPrint('Initiating call to $targetAgent (fast_mode: $fastMode)');

      return true;
    } catch (e) {
      debugPrint('Failed to initiate call: $e');
      return false;
    }
  }

  /// Accept an incoming call
  Future<bool> acceptCall(String callId) async {
    if (_channel == null) return false;

    try {
      _sendMessage({
        'type': 'accept_call',
        'call_id': callId,
      });

      return true;
    } catch (e) {
      debugPrint('Failed to accept call: $e');
      return false;
    }
  }

  /// Decline an incoming call
  Future<bool> declineCall(String callId, {String? reason}) async {
    if (_channel == null) return false;

    try {
      _sendMessage({
        'type': 'decline_call',
        'call_id': callId,
        'reason': reason,
      });

      _updateCallState(CallState.idle);
      return true;
    } catch (e) {
      debugPrint('Failed to decline call: $e');
      return false;
    }
  }

  /// End the current call
  Future<bool> endCall() async {
    // Immediate state update for UI responsiveness
    _updateCallState(CallState.ending);
    await stopRecording();

    // Interrupt any playing audio
    await interruptAudio();

    // Clear local state immediately for UX
    _currentCall = null;
    _callController.add(null);
    _audioQueue.clear();
    _isPlaying = false;

    if (_channel == null) {
       _updateCallState(CallState.idle);
       return false;
    }

    try {
      _sendMessage({'type': 'end_call'});
      
      // Don't rely solely on server response for cleanup
      // But give it a chance to send back stats or final messages
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_callState != CallState.idle) {
          _updateCallState(CallState.idle);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Failed to send end call message: $e');
      // Ensure we reset even if network fails
      _updateCallState(CallState.idle);
      return false;
    }
  }

  /// Put call on hold
  Future<bool> holdCall() async {
    if (_channel == null || _callState != CallState.connected) return false;

    try {
      _sendMessage({'type': 'hold_call'});
      await stopRecording();
      return true;
    } catch (e) {
      debugPrint('Failed to hold call: $e');
      return false;
    }
  }

  /// Resume call from hold
  Future<bool> resumeCall() async {
    if (_channel == null || _callState != CallState.onHold) return false;

    try {
      _sendMessage({'type': 'resume_call'});
      return true;
    } catch (e) {
      debugPrint('Failed to resume call: $e');
      return false;
    }
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('Mute: $_isMuted');
  }

  // ===========================================================================
  // Incoming Call Handlers (for global overlay - uses HTTP)
  // ===========================================================================

  /// Accept an incoming call from the global overlay
  /// This connects to WebSocket and accepts the call
  Future<bool> acceptIncomingCall(String callId) async {
    try {
      // Get session ID from session service
      final sessionService = SessionService();
      final sessionId = await sessionService.getSessionId();

      print('📞 Accepting call $callId, connecting to WebSocket...');

      // Set state to ringing inbound so ActiveCallPage shows UI
      _updateCallState(CallState.ringingInbound);

      // Connect to call WebSocket first
      final connected = await connect(sessionId);
      if (!connected) {
        print('📞 Failed to connect to call WebSocket');
        _updateCallState(CallState.idle);
        return false;
      }

      print('📞 WebSocket connected, accepting call via WebSocket...');

      // Accept the call via WebSocket
      return await acceptCall(callId);
    } catch (e) {
      print('📞 Error accepting incoming call: $e');
      _updateCallState(CallState.idle);
      return false;
    }
  }

  /// Decline an incoming call from the global overlay
  /// This uses HTTP to decline without needing a WebSocket connection
  Future<bool> declineIncomingCall(String callId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No token for declining call');
        return false;
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/calls/$callId/end');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ended_by': 'user_declined'}),
      );

      if (response.statusCode == 200) {
        debugPrint('Call declined successfully');
        return true;
      } else {
        debugPrint('Failed to decline call: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error declining incoming call: $e');
      return false;
    }
  }

  // ===========================================================================
  // Audio Recording
  // ===========================================================================

  /// Start recording and streaming audio
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    try {
      if (!await _recorder.hasPermission()) {
        _errorController.add('Microphone permission denied');
        return false;
      }

      // Interrupt any playing audio when user starts speaking
      await interruptAudio();

      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _recorder.startStream(config);
      _isRecording = true;

      // Start keepalive timer
      _startKeepalive();

      // Stream audio chunks
      _recordingSubscription = stream.listen(
        (chunk) {
          if (!_isMuted && _callState == CallState.connected) {
            _sendAudio(chunk);
          }
        },
        onError: (error) {
          debugPrint('Recording error: $error');
          stopRecording();
        },
      );

      debugPrint('Started recording');
      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _stopKeepalive();

    await _recordingSubscription?.cancel();
    _recordingSubscription = null;

    await _recorder.stop();
    _isRecording = false;

    debugPrint('Stopped recording');
  }

  void _sendAudio(Uint8List audio) {
    if (_channel != null) {
      _channel!.sink.add(audio);
      _lastAudioSentTime = DateTime.now();
    }
  }

  void _startKeepalive() {
    _keepaliveTimer?.cancel();
    _lastAudioSentTime = DateTime.now();

    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (timer) {
      if (!_isRecording || _callState != CallState.connected) {
        timer.cancel();
        return;
      }

      final timeSince = DateTime.now().difference(_lastAudioSentTime!);
      if (timeSince >= _keepaliveInterval) {
        // Send silence packet
        final silence = Uint8List(3200); // 100ms of 16kHz PCM
        _sendAudio(silence);
      }
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
  }

  // ===========================================================================
  // Message Handling
  // ===========================================================================

  void _handleMessage(dynamic data) {
    try {
      // Binary data = TTS audio
      if (data is Uint8List) {
        debugPrint('Received TTS audio: ${data.length} bytes (type: $_pendingAudioType, autoPlay: $_shouldAutoPlayNextAudio)');

        // Only auto-play if this is call audio
        if (_shouldAutoPlayNextAudio && _pendingAudioType == 'call_speech') {
          _playAudio(data);
        } else {
          debugPrint('Skipping auto-play for chat voice audio');
          // For chat audio, we could emit the audio data for the chat UI to handle
          // but for now we just skip it in the call context
        }

        // Reset for next audio
        _shouldAutoPlayNextAudio = true;
        _pendingAudioType = 'call_speech';
        return;
      }

      // JSON message
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      print('📞 Call WS message: $type - ${json.keys.toList()}');

      switch (type) {
        case 'call_state':
          // Initial state on connect - handle like connected if already connected
          _handleCallState(json);
          break;
        case 'call_ringing':
          _handleCallRinging(json);
          break;
        case 'call_connected':
          _handleCallConnected(json);
          break;
        case 'call_ended':
          _handleCallEnded(json);
          break;
        case 'call_on_hold':
          _updateCallState(CallState.onHold);
          break;
        case 'call_transferring':
          _handleCallTransferring(json);
          break;
        case 'transcription':
        case 'transcription_interim':
        case 'transcription_final':
          _handleTranscription(json);
          break;
        case 'agent_speaking':
          // Check audio_type to determine how to handle the audio
          final audioType = json['audio_type'] as String? ?? 'call_speech';
          final autoPlay = json['auto_play'] as bool? ?? true;
          final text = json['text'] as String?;

          // Store audio type for the next audio chunk
          _pendingAudioType = audioType;
          _shouldAutoPlayNextAudio = autoPlay;

          if (audioType == 'call_speech') {
            // Call audio - auto-play and show speaking indicator
            _agentSpeakingController.add(true);
            debugPrint('📞 Agent speaking (call audio): $text');

            // Fallback: if still in ringing state but agent is speaking, auto-connect
            // This handles cases where call_connected message was missed
            if (_callState == CallState.ringingOutbound || _callState == CallState.ringingInbound) {
              debugPrint('📞 Auto-connecting: agent speaking but still in ringing state');
              _updateCallState(CallState.connected);
              startRecording();
            }
          } else {
            // Chat voice message - don't auto-play, don't show call speaking indicator
            // Audio will still be received but not played in call context
            debugPrint('💬 Agent voice message (chat audio, not auto-playing): $text');
          }
          break;
        case 'speaking_completed':
          _agentSpeakingController.add(false);
          break;
        case 'incoming_call':
          _handleIncomingCall(json);
          break;
        case 'error':
          _handleCallError(json);
          break;
        case 'pong':
          // Keepalive response
          break;
        default:
          debugPrint('Unknown call message type: $type');
      }
    } catch (e) {
      debugPrint('Error handling call message: $e');
    }
  }

  void _handleCallState(Map<String, dynamic> json) {
    final callData = json['call'] as Map<String, dynamic>?;
    if (callData != null) {
      _currentCall = Call.fromJson(callData);
      _callController.add(_currentCall);

      // Update state based on call status
      _updateCallState(_currentCall!.status);

      // If already connected, start recording
      if (_currentCall!.status == CallState.connected) {
        startRecording();
      }
    }
  }

  void _handleCallRinging(Map<String, dynamic> json) {
    final callData = json['call'] as Map<String, dynamic>?;
    if (callData != null) {
      _currentCall = Call.fromJson(callData);
      _callController.add(_currentCall);
    }
    _updateCallState(CallState.ringingOutbound);
  }

  void _handleCallConnected(Map<String, dynamic> json) {
    final callData = json['call'] as Map<String, dynamic>?;
    if (callData != null) {
      _currentCall = Call.fromJson(callData);
      _callController.add(_currentCall);
    }
    _updateCallState(CallState.connected);

    // Start recording when connected
    startRecording();
  }

  void _handleCallEnded(Map<String, dynamic> json) {
    _updateCallState(CallState.ended);
    stopRecording();

    final duration = json['duration'] as int?;
    debugPrint('Call ended. Duration: ${duration}s');

    // Clear current call after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _currentCall = null;
      _callController.add(null);
      _updateCallState(CallState.idle);
    });
  }

  void _handleCallTransferring(Map<String, dynamic> json) {
    final fromAgent = json['from_agent'] as String?;
    final toAgent = json['to_agent'] as String?;
    debugPrint('Call transferring from $fromAgent to $toAgent');

    _updateCallState(CallState.transferring);

    // Update current call with new agent
    if (_currentCall != null && toAgent != null) {
      _currentCall = _currentCall!.copyWith(currentAgentId: toAgent);
      _callController.add(_currentCall);
    }
  }

  void _handleTranscription(Map<String, dynamic> json) {
    final text = json['text'] as String? ?? '';
    final isFinal = json['is_final'] as bool? ?? false;
    final confidence = json['confidence'] as double?;

    print('🎤 Transcription received: "$text" (final: $isFinal, confidence: $confidence)');

    final transcript = CallTranscript(
      speakerType: 'user',
      content: text,
      timestamp: DateTime.now(),
      confidence: confidence,
    );

    _transcriptController.add(transcript);
  }

  void _handleIncomingCall(Map<String, dynamic> json) {
    final payload = IncomingCallPayload.fromJson(json);
    _incomingCallController.add(payload);
    _updateCallState(CallState.ringingInbound);
  }

  void _handleCallError(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final message = json['message'] as String?;
    _errorController.add(message ?? 'Call error: $code');
  }

  // ===========================================================================
  // Audio Playback
  // ===========================================================================

  // ===========================================================================
  // Audio Playback
  // ===========================================================================

  void _playAudio(Uint8List audio) {
    _audioQueue.add(audio);
    _processAudioQueue();
  }

  Future<void> _processAudioQueue() async {
    if (_isPlaying || _audioQueue.isEmpty) return;

    _isPlaying = true;
    _agentSpeakingController.add(true);

    try {
      while (_audioQueue.isNotEmpty) {
        final audio = _audioQueue.removeAt(0);
        
        // Use just_audio's bytes source
        await _player.setAudioSource(_BytesAudioSource(audio));
        await _player.play();

        // Wait for completion or stop
        await _player.playerStateStream.firstWhere(
          (state) => 
            state.processingState == ProcessingState.completed || 
            state.processingState == ProcessingState.idle,
        );
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      _isPlaying = false;
      _agentSpeakingController.add(false);
    }
  }

  void _clearAudioQueue() {
    _audioQueue.clear();
    _isPlaying = false;
    _agentSpeakingController.add(false);
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _updateCallState(CallState newState) {
    _callState = newState;
    _callStateController.add(newState);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    await _recorder.dispose();
    await _player.dispose();

    _callStateController.close();
    _callController.close();
    _transcriptController.close();
    _agentSpeakingController.close();
    _incomingCallController.close();
    _errorController.close();
    _connectionStateController.close();
  }

  // ===========================================================================
  // Call History
  // ===========================================================================

  /// Get call history for a session
  Future<CallHistoryResponse?> getCallHistory({
    required String sessionId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No token for getting call history');
        return null;
      }

      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/calls/history/$sessionId?page=$page&page_size=$pageSize',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CallHistoryResponse.fromJson(json);
      } else {
        debugPrint('Failed to get call history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting call history: $e');
      return null;
    }
  }
}

/// Audio source for playing bytes with just_audio
/// Supports MP3 audio from TTS services (ElevenLabs, Cartesia)
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;
  final String _contentType;

  _BytesAudioSource(this._buffer, {String? contentType})
      : _contentType = contentType ?? _detectContentType(_buffer);

  /// Detect audio content type from bytes (magic number detection)
  static String _detectContentType(Uint8List bytes) {
    if (bytes.length < 4) return 'application/octet-stream';

    // Check for MP3 (ID3 tag or sync word)
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return 'audio/mpeg'; // ID3v2 tag
    }
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg'; // MP3 sync word
    }

    // Check for WAV (RIFF header)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'audio/wav';
    }

    // Check for OGG
    if (bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53) {
      return 'audio/ogg';
    }

    // Default to MP3 since ElevenLabs returns MP3
    return 'audio/mpeg';
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: _contentType,
    );
  }
}
