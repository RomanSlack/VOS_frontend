import 'package:flutter/material.dart';
import 'package:vos_app/core/models/social_models.dart';

class AgentProfileCard extends StatelessWidget {
  final AgentProfileDto agent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onStartDm;

  const AgentProfileCard({
    super.key,
    required this.agent,
    required this.isSelected,
    required this.onTap,
    this.onStartDm,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4A4A) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
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
                          agent.displayName,
                          style: const TextStyle(
                            color: Color(0xFFEDEDED),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildOnlineIndicator(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (agent.currentStatus != null)
                    Text(
                      agent.currentStatus!.content,
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (agent.description != null)
                    Text(
                      agent.description!,
                      style: const TextStyle(
                        color: Color(0xFF616161),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              color: const Color(0xFF757575),
              onPressed: onStartDm,
              tooltip: 'Start DM',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getAgentColor(agent.agentId),
          backgroundImage: agent.avatarUrl != null
              ? NetworkImage(agent.avatarUrl!)
              : null,
          child: agent.avatarUrl == null
              ? Text(
                  _getAgentEmoji(agent.agentId),
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        // Online indicator
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: agent.isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF212121),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: agent.isOnline
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        agent.isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: agent.isOnline ? Colors.green : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
      case 'browser_agent':
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
      case 'browser_agent':
        return Colors.indigo.shade700;
      default:
        return const Color(0xFF4A4A4A);
    }
  }
}
