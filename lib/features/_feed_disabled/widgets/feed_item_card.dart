import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/social_models.dart';

/// Card widget for displaying a feed item (story or status)
class FeedItemCard extends StatelessWidget {
  final FeedItemDto item;
  final VoidCallback? onTap;
  final void Function(String agentId)? onAgentTap;
  final void Function(String agentId)? onStartDm;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAgentTap,
    this.onStartDm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (item.story != null) _buildStoryContent(),
            if (item.status != null) _buildStatusContent(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onAgentTap?.call(item.agentId),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _getAgentColor(item.agentId),
              child: Text(
                _getAgentEmoji(item.agentId),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onAgentTap?.call(item.agentId),
                  child: Text(
                    item.agentDisplayName ?? item.agentId,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _getItemTypeIcon(),
                      size: 12,
                      color: const Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getItemTypeLabel(),
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\u{2022}',
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(item.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
            color: const Color(0xFF424242),
            onSelected: (value) {
              if (value == 'dm') {
                onStartDm?.call(item.agentId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dm',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFFEDEDED)),
                    SizedBox(width: 8),
                    Text('Start DM', style: TextStyle(color: Color(0xFFEDEDED))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Color(0xFFEDEDED)),
                    SizedBox(width: 8),
                    Text('View Profile', style: TextStyle(color: Color(0xFFEDEDED))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    final story = item.story!;

    if (story.mediaUrl != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          story.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFF424242),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF757575)),
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (story.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                story.title!,
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            story.content,
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    final status = item.status!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          if (status.mood != null)
            Text(
              status.mood!,
              style: const TextStyle(fontSize: 24),
            ),
          if (status.mood != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.content,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          if (item.story != null) ...[
            Icon(
              Icons.visibility,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              '${item.story!.viewCount} views',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (item.story?.expiresAt != null) ...[
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _getExpiryText(item.story!.expiresAt!),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: Colors.white.withOpacity(0.5),
            ),
            onPressed: () => onStartDm?.call(item.agentId),
            tooltip: 'Reply',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  IconData _getItemTypeIcon() {
    switch (item.itemType) {
      case FeedItemType.story:
        final story = item.story!;
        switch (story.storyType) {
          case StoryType.text:
            return Icons.text_fields;
          case StoryType.image:
            return Icons.image;
          case StoryType.taskCompletion:
            return Icons.check_circle_outline;
          case StoryType.insight:
            return Icons.lightbulb_outline;
        }
      case FeedItemType.status:
        return Icons.mood;
    }
  }

  String _getItemTypeLabel() {
    switch (item.itemType) {
      case FeedItemType.story:
        final story = item.story!;
        switch (story.storyType) {
          case StoryType.text:
            return 'Story';
          case StoryType.image:
            return 'Photo';
          case StoryType.taskCompletion:
            return 'Task Completed';
          case StoryType.insight:
            return 'Insight';
        }
      case FeedItemType.status:
        return 'Status update';
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('MMM d').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  String _getExpiryText(String expiresAt) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final diff = expiry.difference(now);

      if (diff.isNegative) return 'Expired';
      if (diff.inHours < 1) return '${diff.inMinutes}m left';
      if (diff.inHours < 24) return '${diff.inHours}h left';
      return '${diff.inDays}d left';
    } catch (_) {
      return '';
    }
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
