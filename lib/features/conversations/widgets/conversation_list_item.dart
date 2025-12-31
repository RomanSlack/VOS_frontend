import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/social_models.dart';

class ConversationListItem extends StatelessWidget {
  final ConversationDto conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A4A4A)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? Colors.blue
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getDisplayName(),
                          style: TextStyle(
                            color: const Color(0xFFEDEDED),
                            fontSize: 14,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          _formatTime(conversation.lastMessageAt!),
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? Colors.blue.shade300
                                : const Color(0xFF757575),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview ?? 'No messages yet',
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF757575),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final isGroup = conversation.conversationType == ConversationType.group;
    final isAgentChat = conversation.conversationType == ConversationType.agentChat;

    if (isGroup || isAgentChat) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF4A4A4A),
        child: Icon(
          isAgentChat ? Icons.smart_toy : Icons.group,
          color: const Color(0xFFEDEDED),
          size: 20,
        ),
      );
    }

    // DM - show the other participant
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.participantType == ParticipantType.agent,
      orElse: () => conversation.participants.first,
    );

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getAgentColor(otherParticipant.participantId),
          child: Text(
            _getAgentEmoji(otherParticipant.participantId),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        // Online indicator could go here
      ],
    );
  }

  String _getDisplayName() {
    if (conversation.name != null && conversation.name!.isNotEmpty) {
      return conversation.name!;
    }

    if (conversation.conversationType == ConversationType.dm) {
      final other = conversation.participants.firstWhere(
        (p) => p.participantType == ParticipantType.agent,
        orElse: () => conversation.participants.first,
      );
      return _formatAgentName(other.participantId);
    }

    return 'Group Chat';
  }

  String _formatAgentName(String agentId) {
    // Convert agent_id to display name
    return agentId
        .replaceAll('_agent', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _getAgentEmoji(String agentId) {
    switch (agentId) {
      case 'weather_agent':
        return '';
      case 'calendar_agent':
        return '';
      case 'notes_agent':
        return '';
      case 'calculator_agent':
        return '';
      case 'search_agent':
        return '';
      case 'primary_agent':
        return '';
      default:
        return '';
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
      default:
        return const Color(0xFF4A4A4A);
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return DateFormat('EEE').format(dateTime);
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }
}
