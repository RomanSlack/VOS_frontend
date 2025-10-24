import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vos_app/core/models/voice_models.dart';
import 'package:vos_app/core/services/voice_service.dart';

/// Voice UI state manager
/// Extends ChangeNotifier to notify UI of state changes
class VoiceManager extends ChangeNotifier {
  final VoiceService _voiceService;

  // State
  VoiceState _voiceState = VoiceState.idle;
  VoiceConnectionState _connectionState = VoiceConnectionState.disconnected;
  String? _sessionId;

  // Transcription
  String _interimTranscription = '';
  String _finalTranscription = '';
  double? _transcriptionConfidence;

  // Agent status
  String? _agentStatusMessage;

  // Speaking
  String? _speakingText;
  int? _estimatedDurationMs;

  // Audio
  String? _lastAudioFilePath;
  int? _lastAudioDurationMs;

  // Error
  VoiceErrorPayload? _lastError;

  // Subscriptions
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _voiceStateSubscription;
  StreamSubscription? _sessionStartedSubscription;
  StreamSubscription? _listeningStartedSubscription;
  StreamSubscription? _transcriptionInterimSubscription;
  StreamSubscription? _transcriptionFinalSubscription;
  StreamSubscription? _agentThinkingSubscription;
  StreamSubscription? _speakingStartedSubscription;
  StreamSubscription? _speakingCompletedSubscription;
  StreamSubscription? _audioReceivedSubscription;
  StreamSubscription? _errorSubscription;

  // Public getters
  VoiceState get voiceState => _voiceState;
  VoiceConnectionState get connectionState => _connectionState;
  String? get sessionId => _sessionId;
  String get interimTranscription => _interimTranscription;
  String get finalTranscription => _finalTranscription;
  double? get transcriptionConfidence => _transcriptionConfidence;
  String? get agentStatusMessage => _agentStatusMessage;
  String? get speakingText => _speakingText;
  int? get estimatedDurationMs => _estimatedDurationMs;
  String? get lastAudioFilePath => _lastAudioFilePath;
  int? get lastAudioDurationMs => _lastAudioDurationMs;
  VoiceErrorPayload? get lastError => _lastError;

  bool get isConnected =>
      _connectionState == VoiceConnectionState.connected;
  bool get isIdle => _voiceState == VoiceState.idle;
  bool get isListening => _voiceState == VoiceState.listening;
  bool get isProcessing => _voiceState == VoiceState.processing;
  bool get isSpeaking => _voiceState == VoiceState.speaking;
  bool get hasError => _voiceState == VoiceState.error;

  /// Get combined transcription (interim + final)
  String get currentTranscription {
    if (_interimTranscription.isNotEmpty) {
      if (_finalTranscription.isNotEmpty) {
        return '$_finalTranscription $_interimTranscription';
      }
      return _interimTranscription;
    }
    return _finalTranscription;
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (hasError) {
      return _lastError?.message ?? 'Error occurred';
    }

    switch (_voiceState) {
      case VoiceState.idle:
        return isConnected ? 'Ready to listen' : 'Connecting...';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return _agentStatusMessage ?? 'Processing...';
      case VoiceState.speaking:
        return 'Speaking...';
      case VoiceState.error:
        return _lastError?.message ?? 'Error occurred';
    }
  }

  VoiceManager(this._voiceService) {
    _setupListeners();
  }

  /// Setup listeners for voice service streams
  void _setupListeners() {
    _connectionStateSubscription =
        _voiceService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _voiceStateSubscription = _voiceService.voiceStateStream.listen((state) {
      _voiceState = state;
      notifyListeners();
    });

    _sessionStartedSubscription =
        _voiceService.sessionStartedStream.listen((payload) {
      _sessionId = payload.sessionId;
      debugPrint('🎙️ Voice session started: ${payload.sessionId}');
      notifyListeners();
    });

    _listeningStartedSubscription =
        _voiceService.listeningStartedStream.listen((payload) {
      debugPrint('👂 Listening started');
      // Clear previous transcriptions when starting new listening session
      _interimTranscription = '';
      _finalTranscription = '';
      notifyListeners();
    });

    _transcriptionInterimSubscription =
        _voiceService.transcriptionInterimStream.listen((payload) {
      _interimTranscription = payload.text;
      debugPrint('📝 Interim: ${payload.text}');
      notifyListeners();
    });

    _transcriptionFinalSubscription =
        _voiceService.transcriptionFinalStream.listen((payload) {
      _finalTranscription = payload.text;
      _transcriptionConfidence = payload.confidence;
      _interimTranscription = ''; // Clear interim when final is received
      debugPrint('✅ Final: ${payload.text} (confidence: ${payload.confidence})');
      notifyListeners();
    });

    _agentThinkingSubscription =
        _voiceService.agentThinkingStream.listen((payload) {
      _agentStatusMessage = payload.status;
      debugPrint('🤔 Agent: ${payload.status}');
      notifyListeners();
    });

    _speakingStartedSubscription =
        _voiceService.speakingStartedStream.listen((payload) {
      _speakingText = payload.text;
      _estimatedDurationMs = payload.estimatedDurationMs;
      debugPrint('🗣️ Speaking: ${payload.text}');
      notifyListeners();
    });

    _speakingCompletedSubscription =
        _voiceService.speakingCompletedStream.listen((payload) {
      _speakingText = null;
      _estimatedDurationMs = null;
      debugPrint('✅ Speaking completed');
      notifyListeners();
    });

    _audioReceivedSubscription =
        _voiceService.audioReceivedStream.listen((payload) {
      _lastAudioFilePath = payload.audioUrl;
      _lastAudioDurationMs = payload.durationMs;
      debugPrint('🎵 Audio URL received: ${payload.audioUrl}');
      notifyListeners();
    });

    _errorSubscription = _voiceService.errorStream.listen((payload) {
      _lastError = payload;
      debugPrint('❌ Error: ${payload.message}');
      notifyListeners();
    });
  }

  /// Connect to voice session
  Future<void> connect(String sessionId) async {
    _sessionId = sessionId;
    await _voiceService.connect(sessionId);
  }

  /// Start listening (recording and sending audio)
  Future<void> startListening() async {
    // Clear error state
    if (_voiceState == VoiceState.error) {
      _lastError = null;
    }

    await _voiceService.startListening();
  }

  /// Stop listening (stop recording)
  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  /// Disconnect from voice session
  Future<void> disconnect() async {
    await _voiceService.disconnect();
    _sessionId = null;
    _resetState();
  }

  /// Reset all state
  void _resetState() {
    _voiceState = VoiceState.idle;
    _interimTranscription = '';
    _finalTranscription = '';
    _transcriptionConfidence = null;
    _agentStatusMessage = null;
    _speakingText = null;
    _estimatedDurationMs = null;
    _lastAudioFilePath = null;
    _lastAudioDurationMs = null;
    _lastError = null;
    notifyListeners();
  }

  /// Clear transcriptions (useful when starting new interaction)
  void clearTranscriptions() {
    _interimTranscription = '';
    _finalTranscription = '';
    _transcriptionConfidence = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _lastError = null;
    if (_voiceState == VoiceState.error) {
      _voiceState = VoiceState.idle;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _connectionStateSubscription?.cancel();
    _voiceStateSubscription?.cancel();
    _sessionStartedSubscription?.cancel();
    _listeningStartedSubscription?.cancel();
    _transcriptionInterimSubscription?.cancel();
    _transcriptionFinalSubscription?.cancel();
    _agentThinkingSubscription?.cancel();
    _speakingStartedSubscription?.cancel();
    _speakingCompletedSubscription?.cancel();
    _audioReceivedSubscription?.cancel();
    _errorSubscription?.cancel();

    super.dispose();
  }
}
