import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/feed/bloc/feed_bloc.dart';
import 'package:vos_app/features/feed/bloc/feed_event.dart';
import 'package:vos_app/features/feed/bloc/feed_state.dart';

/// Full-screen story viewer with Instagram-like progress bars
class StoryViewer extends StatefulWidget {
  final AgentStoryDto story;
  final bool canGoNext;
  final bool canGoPrevious;

  const StoryViewer({
    super.key,
    required this.story,
    this.canGoNext = false,
    this.canGoPrevious = false,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _autoAdvanceTimer;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressComplete);
    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant StoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story.storyId != widget.story.storyId) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (widget.canGoNext) {
        context.read<FeedBloc>().add(const NextStory());
      } else {
        // Close viewer when last story completes
        context.read<FeedBloc>().add(const ClearSelectedStory());
      }
    }
  }

  void _handleTapLeft() {
    if (widget.canGoPrevious) {
      context.read<FeedBloc>().add(const PreviousStory());
    }
  }

  void _handleTapRight() {
    if (widget.canGoNext) {
      context.read<FeedBloc>().add(const NextStory());
    } else {
      context.read<FeedBloc>().add(const ClearSelectedStory());
    }
  }

  void _handleLongPressStart(_) {
    _progressController.stop();
  }

  void _handleLongPressEnd(_) {
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        final feedState = state as FeedLoaded;
        final storyQueue = feedState.storyQueue;
        final currentIndex = feedState.selectedStoryIndex;

        return GestureDetector(
          onLongPressStart: _handleLongPressStart,
          onLongPressEnd: _handleLongPressEnd,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Story content
                _buildContent(),

                // Progress bars
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  child: _buildProgressBars(storyQueue.length, currentIndex),
                ),

                // Header with agent info and close button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 8,
                  right: 8,
                  child: _buildHeader(),
                ),

                // Tap zones for navigation
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _handleTapLeft,
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _handleTapRight,
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBars(int total, int current) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            height: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: index < current
                  ? Container(color: Colors.white)
                  : index == current
                      ? AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            );
                          },
                        )
                      : Container(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _getAgentColor(widget.story.agentId),
          child: Text(
            _getAgentEmoji(widget.story.agentId),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.story.agentDisplayName ?? widget.story.agentId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTime(widget.story.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            context.read<FeedBloc>().add(const ClearSelectedStory());
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    final story = widget.story;

    // If story has media, show it
    if (story.mediaUrl != null) {
      return Center(
        child: Image.network(
          story.mediaUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            );
          },
        ),
      );
    }

    // Text-based story
    return Container(
      decoration: BoxDecoration(
        gradient: _getStoryGradient(story.storyType),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStoryIcon(story.storyType),
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 24),
              if (story.title != null)
                Text(
                  story.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              Text(
                story.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${story.viewCount} views',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getStoryGradient(StoryType type) {
    switch (type) {
      case StoryType.text:
        return const LinearGradient(
          colors: [Color(0xFF405DE6), Color(0xFF5851DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case StoryType.taskCompletion:
        return const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF1DE9B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case StoryType.insight:
        return const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFFAB00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case StoryType.image:
        return const LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFC13584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getStoryIcon(StoryType type) {
    switch (type) {
      case StoryType.text:
        return Icons.text_fields;
      case StoryType.image:
        return Icons.image;
      case StoryType.taskCompletion:
        return Icons.check_circle;
      case StoryType.insight:
        return Icons.lightbulb;
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

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(dateTime);
    } catch (_) {
      return '';
    }
  }
}
