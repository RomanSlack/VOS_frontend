import 'package:flutter/material.dart';
import 'package:vos_app/core/models/social_models.dart';

/// Story ring widget that shows agent avatar with gradient border for unviewed stories
class StoryRing extends StatelessWidget {
  final String agentId;
  final String displayName;
  final String? avatarUrl;
  final bool hasUnviewedStories;
  final bool isOnline;
  final VoidCallback? onTap;
  final double size;

  const StoryRing({
    super.key,
    required this.agentId,
    required this.displayName,
    this.avatarUrl,
    this.hasUnviewedStories = false,
    this.isOnline = false,
    this.onTap,
    this.size = 64,
  });

  factory StoryRing.fromAgent(
    AgentProfileDto agent, {
    bool hasUnviewedStories = false,
    VoidCallback? onTap,
    double size = 64,
  }) {
    return StoryRing(
      agentId: agent.agentId,
      displayName: agent.displayName,
      avatarUrl: agent.avatarUrl,
      hasUnviewedStories: hasUnviewedStories,
      isOnline: agent.isOnline,
      onTap: onTap,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringPadding = size * 0.05;
    final avatarRadius = (size - ringPadding * 4) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnviewedStories
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF405DE6),
                        Color(0xFF5851DB),
                        Color(0xFF833AB4),
                        Color(0xFFC13584),
                        Color(0xFFE1306C),
                        Color(0xFFFD1D1D),
                        Color(0xFFF56040),
                        Color(0xFFF77737),
                        Color(0xFFFCAF45),
                        Color(0xFFFFDC80),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              border: !hasUnviewedStories
                  ? Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(ringPadding * 2),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212121),
                ),
                padding: EdgeInsets.all(ringPadding / 2),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: _getAgentColor(agentId),
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                      child: avatarUrl == null
                          ? Text(
                              _getAgentEmoji(agentId),
                              style: TextStyle(fontSize: avatarRadius * 0.7),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: size * 0.18,
                          height: size * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF212121),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 8,
            child: Text(
              displayName.split(' ').first,
              style: TextStyle(
                color: const Color(0xFFEDEDED),
                fontSize: size * 0.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getAgentEmoji(String agentId) {
    switch (agentId) {
      case 'weather_agent':
        return '\u{1F326}';
      case 'calendar_agent':
        return '\u{1F4C5}';
      case 'notes_agent':
        return '\u{1F4DD}';
      case 'calculator_agent':
        return '\u{1F522}';
      case 'search_agent':
        return '\u{1F50D}';
      case 'primary_agent':
        return '\u{1F916}';
      case 'browser_agent':
        return '\u{1F310}';
      default:
        return '\u{1F916}';
    }
  }

  Color _getAgentColor(String agentId) {
    switch (agentId) {
      case 'weather_agent':
        return Colors.blue.shade700;
      case 'calendar_agent':
        return Colors.green.shade700;
      case 'notes_agent':
        return Colors.amber.shade700;
      case 'calculator_agent':
        return Colors.purple.shade700;
      case 'search_agent':
        return Colors.orange.shade700;
      case 'primary_agent':
        return Colors.teal.shade700;
      case 'browser_agent':
        return Colors.indigo.shade700;
      default:
        return const Color(0xFF4A4A4A);
    }
  }
}
