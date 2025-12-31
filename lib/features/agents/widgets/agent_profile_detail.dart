import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/social_models.dart';

class AgentProfileDetail extends StatelessWidget {
  final AgentProfileDto agent;
  final AgentHealthDto? health;
  final List<AgentStoryDto> stories;
  final bool showBackButton;
  final VoidCallback? onBack;
  final void Function(String agentId) onStartDm;

  const AgentProfileDetail({
    super.key,
    required this.agent,
    this.health,
    this.stories = const [],
    this.showBackButton = false,
    this.onBack,
    required this.onStartDm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 24),
                if (health != null) _buildHealthCard(),
                if (stories.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildStoriesSection(),
                ],
                const SizedBox(height: 24),
                _buildCapabilities(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFEDEDED)),
              onPressed: onBack,
            ),
          const Text(
            'Agent Profile',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: _getAgentColor(agent.agentId),
                backgroundImage: agent.avatarUrl != null
                    ? NetworkImage(agent.avatarUrl!)
                    : null,
                child: agent.avatarUrl == null
                    ? Text(
                        _getAgentEmoji(agent.agentId),
                        style: const TextStyle(fontSize: 36),
                      )
                    : null,
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: agent.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF212121),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            agent.displayName,
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            agent.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: agent.isOnline ? Colors.green : Colors.grey,
              fontSize: 14,
            ),
          ),
          if (agent.description != null) ...[
            const SizedBox(height: 8),
            Text(
              agent.description!,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => onStartDm(agent.agentId),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Start Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = agent.currentStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mood, color: Color(0xFF757575), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Current Status',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (status?.mood != null)
                Text(
                  status!.mood!,
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status?.content ?? 'No status set',
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart, color: Color(0xFF757575), size: 18),
              SizedBox(width: 8),
              Text(
                'Health Status',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHealthRow(
            'Status',
            health!.isOnline ? 'Online' : 'Offline',
            health!.isOnline ? Colors.green : Colors.red,
          ),
          if (health!.lastHeartbeat != null)
            _buildHealthRow(
              'Last Heartbeat',
              _formatTime(health!.lastHeartbeat!),
              null,
            ),
          if (health!.startedAt != null)
            _buildHealthRow(
              'Started',
              _formatTime(health!.startedAt!),
              null,
            ),
          if (health!.crashCount > 0) ...[
            _buildHealthRow(
              'Crash Count',
              health!.crashCount.toString(),
              Colors.orange,
            ),
            if (health!.lastCrashReason != null)
              _buildHealthRow(
                'Last Crash',
                health!.lastCrashReason!,
                Colors.red,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFEDEDED),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_stories, color: Color(0xFF757575), size: 18),
            SizedBox(width: 8),
            Text(
              'Recent Stories',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              return _buildStoryCard(stories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard(AgentStoryDto story) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: story.isViewed
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.5),
          width: story.isViewed ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStoryIcon(story.storyType),
                color: const Color(0xFF757575),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                story.storyType.name,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (!story.isViewed)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (story.title != null)
            Text(
              story.title!,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              story.content,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilities() {
    if (agent.capabilities == null || agent.capabilities!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFF757575), size: 18),
              SizedBox(width: 8),
              Text(
                'Capabilities',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agent.capabilities!.map((capability) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  capability,
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getStoryIcon(StoryType type) {
    switch (type) {
      case StoryType.text:
        return Icons.text_fields;
      case StoryType.image:
        return Icons.image;
      case StoryType.taskCompletion:
        return Icons.check_circle_outline;
      case StoryType.insight:
        return Icons.lightbulb_outline;
    }
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

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, HH:mm').format(dateTime);
    } catch (_) {
      return timestamp;
    }
  }
}
