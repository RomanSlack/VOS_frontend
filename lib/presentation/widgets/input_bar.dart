import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/core/modal_manager.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;

    // Open chat app with the message
    widget.modalManager.openModal('chat', initialMessage: text);

    // Clear the input
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 600,
      margin: const EdgeInsets.only(bottom: 24),
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
            CircleIcon(
              icon: Icons.mic_none_outlined,
              size: 40,
              useFontAwesome: false,
              onPressed: () {
                // Handle microphone tap
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