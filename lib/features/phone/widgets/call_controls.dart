import 'package:flutter/material.dart';

/// Call control buttons (mute, hold, end)
class CallControls extends StatelessWidget {
  final bool isMuted;
  final bool isOnHold;
  final VoidCallback onMutePressed;
  final VoidCallback onHoldPressed;
  final VoidCallback onEndPressed;

  const CallControls({
    super.key,
    required this.isMuted,
    required this.isOnHold,
    required this.onMutePressed,
    required this.onHoldPressed,
    required this.onEndPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _ControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            label: isMuted ? 'Unmute' : 'Mute',
            isActive: isMuted,
            onPressed: onMutePressed,
          ),

          // Hold button
          _ControlButton(
            icon: isOnHold ? Icons.play_arrow : Icons.pause,
            label: isOnHold ? 'Resume' : 'Hold',
            isActive: isOnHold,
            onPressed: onHoldPressed,
          ),

          // End call button
          _ControlButton(
            icon: Icons.call_end,
            label: 'End',
            isDestructive: true,
            onPressed: onEndPressed,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? Colors.red
        : isActive
            ? Colors.white
            : Colors.white24;

    final iconColor = isDestructive
        ? Colors.white
        : isActive
            ? Colors.black
            : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
