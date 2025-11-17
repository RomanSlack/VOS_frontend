import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/managers/voice_manager.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/utils/chat_toast.dart';

class InputBar extends StatefulWidget {
  final VosModalManager modalManager;

  const InputBar({
    super.key,
    required this.modalManager,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final VoiceManager _voiceManager;

  // Hold-to-record state
  bool _isHolding = false;
  Timer? _holdDurationTimer;
  static const Duration _maxHoldDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _voiceManager = getIt<VoiceManager>();

    // Connect to voice service using the same session ID as chat
    _voiceManager.connect(VosModalManager.defaultSessionId);

    // Listen for final transcriptions and audio
    _voiceManager.addListener(_onVoiceStateChanged);
  }

  void _onVoiceStateChanged() {
    // When we get a final transcription, auto-send as voice message
    final transcription = _voiceManager.finalTranscription;
    if (transcription.isNotEmpty && _controller.text != transcription) {
      _controller.text = transcription;

      // Add a small delay before auto-sending to give user time to review
      Future.delayed(const Duration(milliseconds: 800), () {
        // Check if the transcription is still the same (user didn't edit)
        if (_controller.text == transcription) {
          _handleVoiceSubmit(transcription);
        }
      });
    }

    // When we receive audio, attach it to the latest AI message
    final audioFilePath = _voiceManager.lastAudioFilePath;
    if (audioFilePath != null) {
      widget.modalManager.chatManager.attachAudioToLatestAIMessage(
        audioFilePath,
        audioDurationMs: _voiceManager.lastAudioDurationMs,
      );
    }
  }

  @override
  void dispose() {
    _holdDurationTimer?.cancel();
    _voiceManager.removeListener(_onVoiceStateChanged);
    _voiceManager.disconnect();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    // Clear the input immediately for better UX
    _controller.clear();
    _focusNode.unfocus();

    // Add optimistic message immediately
    final messageId = widget.modalManager.chatManager.addOptimisticMessage(text);

    // Only open chat if it's not already visible
    final isChatVisible = widget.modalManager.isModalOpen('chat') &&
                          !widget.modalManager.isModalMinimized('chat');

    if (!isChatVisible) {
      widget.modalManager.openModal('chat');
    }

    // The ChatApp will detect the new user message and trigger the AI response
    // which will handle updating the message status
  }

  void _handleVoiceSubmit(String text) async {
    if (text.trim().isEmpty) return;

    // Gather voice metadata
    final voiceMetadata = VoiceMetadata(
      sessionId: VosModalManager.defaultSessionId,
      confidence: _voiceManager.transcriptionConfidence,
      model: 'nova-2', // Deepgram model
    );

    // Stop listening immediately
    await _voiceManager.stopListening();

    // Clear the input and transcription
    _controller.clear();
    _focusNode.unfocus();
    _voiceManager.clearTranscriptions();

    // Add optimistic voice message with metadata
    final messageId = widget.modalManager.chatManager.addOptimisticMessage(
      text,
      inputMode: 'voice',
      voiceMetadata: voiceMetadata,
    );

    // Only open chat if it's not already visible
    final isChatVisible = widget.modalManager.isModalOpen('chat') &&
                          !widget.modalManager.isModalMinimized('chat');

    if (!isChatVisible) {
      widget.modalManager.openModal('chat');
    }

    // The ChatApp will detect the new user message and trigger the AI response
  }

  void _onMicTap() {
    // Single tap: toggle recording on/off (normal mode with endpointing)
    if (_voiceManager.isListening) {
      _voiceManager.stopListening();
    } else {
      _voiceManager.startListening();
    }
  }

  void _onMicLongPressStart() {
    // Long press start: start recording in hold mode
    setState(() {
      _isHolding = true;
    });

    // Start listening in hold mode (disables automatic silence detection)
    _voiceManager.startListening(holdMode: true);

    // Start timer to enforce max hold duration
    _holdDurationTimer = Timer(_maxHoldDuration, () {
      if (_isHolding) {
        _onMicLongPressEnd();
      }
    });
  }

  void _onMicLongPressEnd() {
    // Long press end: stop recording immediately
    _holdDurationTimer?.cancel();
    _holdDurationTimer = null;

    setState(() {
      _isHolding = false;
    });

    _voiceManager.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive width: full width on mobile, fixed 600px on desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final containerWidth = isMobile ? double.infinity : 600.0;

    return Container(
      height: 60,
      width: containerWidth,
      margin: EdgeInsets.only(bottom: isMobile ? 0 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
        // Simple uniform border for bevel effect
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything',
                  hintStyle: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false, // Ensure no fill color
                  fillColor: Colors.transparent, // Explicitly transparent
                  contentPadding: EdgeInsets.only(left: 8), // Small left padding
                ),
                cursorColor: Colors.white,
                onSubmitted: _handleSubmit,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 12),
            ListenableBuilder(
              listenable: _voiceManager,
              builder: (context, child) {
                final isListening = _voiceManager.isListening;
                final backgroundColor = _isHolding
                    ? Colors.orange.shade700
                    : (isListening ? Colors.red.shade700 : null);

                return GestureDetector(
                  onTap: _onMicTap,
                  onLongPressStart: (_) => _onMicLongPressStart(),
                  onLongPressEnd: (_) => _onMicLongPressEnd(),
                  child: CircleIcon(
                    icon: isListening ? Icons.mic : Icons.mic_none_outlined,
                    size: 40,
                    useFontAwesome: false,
                    onPressed: null, // Disabled, using GestureDetector instead
                    backgroundColor: backgroundColor,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            CircleIcon(
              icon: Icons.graphic_eq_outlined,
              size: 40,
              useFontAwesome: false,
              onPressed: () {
                // Handle waveform tap
              },
            ),
          ],
        ),
      ),
    );
  }
}