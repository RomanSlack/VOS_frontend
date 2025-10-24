import 'package:flutter/material.dart';
import 'package:vos_app/core/models/voice_models.dart';
import 'package:vos_app/core/managers/voice_manager.dart';
import 'package:vos_app/core/services/voice_service.dart';
import 'package:vos_app/core/di/injection.dart';

/// Voice chat widget with microphone button and live transcription
class VoiceChatWidget extends StatefulWidget {
  final String sessionId;

  const VoiceChatWidget({
    super.key,
    required this.sessionId,
  });

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget> {
  late final VoiceManager _voiceManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _voiceManager = getIt<VoiceManager>();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceManager.connect(widget.sessionId);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize voice: $e');
    }
  }

  @override
  void dispose() {
    _voiceManager.disconnect();
    super.dispose();
  }

  void _onMicButtonPressed() {
    if (_voiceManager.isListening) {
      _voiceManager.stopListening();
    } else {
      _voiceManager.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _voiceManager,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status message
              _buildStatusIndicator(),
              const SizedBox(height: 32),

              // Microphone button
              _buildMicrophoneButton(),
              const SizedBox(height: 32),

              // Transcription display
              if (_voiceManager.currentTranscription.isNotEmpty)
                _buildTranscriptionDisplay(),

              // Speaking text display
              if (_voiceManager.speakingText != null)
                _buildSpeakingDisplay(),

              // Error display
              if (_voiceManager.hasError) _buildErrorDisplay(),

              const SizedBox(height: 16),

              // Connection status
              _buildConnectionStatus(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator() {
    final status = _voiceManager.statusMessage;
    Color statusColor;

    if (_voiceManager.hasError) {
      statusColor = Colors.red;
    } else if (_voiceManager.isSpeaking) {
      statusColor = Colors.blue;
    } else if (_voiceManager.isProcessing) {
      statusColor = Colors.orange;
    } else if (_voiceManager.isListening) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    final isListening = _voiceManager.isListening;
    final isProcessing = _voiceManager.isProcessing;
    final isSpeaking = _voiceManager.isSpeaking;
    final isDisabled = !_isInitialized ||
        !_voiceManager.isConnected ||
        isProcessing ||
        isSpeaking;

    return GestureDetector(
      onTap: isDisabled ? null : _onMicButtonPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDisabled
              ? Colors.grey.shade300
              : isListening
                  ? Colors.red.shade400
                  : Colors.blue.shade400,
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    final transcription = _voiceManager.currentTranscription;
    final isFinal = _voiceManager.interimTranscription.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinal ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFinal ? Icons.check_circle : Icons.pending,
                size: 16,
                color: isFinal ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isFinal ? 'Final Transcription' : 'Listening...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFinal ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transcription,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakingDisplay() {
    final speakingText = _voiceManager.speakingText ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Agent Speaking',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            speakingText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    final error = _voiceManager.lastError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error?.message ?? 'Unknown error',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _voiceManager.clearError(),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final connectionState = _voiceManager.connectionState;
    String statusText;
    Color statusColor;

    switch (connectionState) {
      case VoiceConnectionState.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case VoiceConnectionState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        break;
      case VoiceConnectionState.reconnecting:
        statusText = 'Reconnecting...';
        statusColor = Colors.orange;
        break;
      case VoiceConnectionState.disconnected:
        statusText = 'Disconnected';
        statusColor = Colors.red;
        break;
    }

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 12,
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
