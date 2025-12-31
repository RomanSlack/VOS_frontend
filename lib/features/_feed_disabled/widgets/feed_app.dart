import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/conversations/bloc/conversations_bloc.dart';
import 'package:vos_app/features/conversations/bloc/conversations_event.dart';
import 'package:vos_app/features/feed/bloc/feed_bloc.dart';
import 'package:vos_app/features/feed/bloc/feed_event.dart';
import 'package:vos_app/features/feed/bloc/feed_state.dart';
import 'package:vos_app/features/feed/widgets/feed_item_card.dart';
import 'package:vos_app/features/feed/widgets/story_ring.dart';
import 'package:vos_app/features/feed/widgets/story_viewer.dart';

class FeedApp extends StatefulWidget {
  const FeedApp({super.key});

  @override
  State<FeedApp> createState() => _FeedAppState();
}

class _FeedAppState extends State<FeedApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedBloc>().add(const LoadFeed());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          // Show story viewer if a story is selected
          if (state is FeedLoaded && state.selectedStory != null) {
            return StoryViewer(
              story: state.selectedStory!,
              canGoNext: state.canGoNext,
              canGoPrevious: state.canGoPrevious,
            );
          }

          return Column(
            children: [
              _buildHeader(state),
              Expanded(
                child: _buildContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(FeedState state) {
    final unviewedCount = state is FeedLoaded ? state.unviewedStoriesCount : 0;

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
          const Icon(
            Icons.dynamic_feed,
            color: Color(0xFFEDEDED),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Feed',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (unviewedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unviewedCount new',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (state is FeedLoaded) _buildFilterChips(state),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF757575)),
            onPressed: () {
              context.read<FeedBloc>().add(const RefreshFeed());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(FeedLoaded state) {
    return PopupMenuButton<FeedFilterType>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getFilterLabel(state.filterType),
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
        ],
      ),
      color: const Color(0xFF424242),
      onSelected: (filterType) {
        context.read<FeedBloc>().add(FilterFeed(filterType));
      },
      itemBuilder: (context) => FeedFilterType.values.map((type) {
        final isSelected = type == state.filterType;
        return PopupMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(
                _getFilterIcon(type),
                size: 18,
                color: isSelected ? Colors.blue : const Color(0xFFEDEDED),
              ),
              const SizedBox(width: 8),
              Text(
                _getFilterLabel(type),
                style: TextStyle(
                  color: isSelected ? Colors.blue : const Color(0xFFEDEDED),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: Colors.blue),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(FeedState state) {
    if (state is FeedLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF757575)),
      );
    }

    if (state is FeedError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<FeedBloc>().add(const RefreshFeed());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is! FeedLoaded) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FeedBloc>().add(const RefreshFeed());
      },
      child: CustomScrollView(
        slivers: [
          // Stories row
          if (state.stories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildStoriesRow(state),
            ),

          // Agent statuses
          if (state.activeStatuses.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildStatusesSection(state),
            ),

          // Feed items
          if (state.filteredItems.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= state.filteredItems.length) {
                    if (state.hasMore && !state.isLoadingMore) {
                      // Load more when reaching the end
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.read<FeedBloc>().add(const LoadMoreFeed());
                      });
                    }
                    if (state.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF757575),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final item = state.filteredItems[index];
                  return FeedItemCard(
                    item: item,
                    onTap: () {
                      if (item.story != null) {
                        context.read<FeedBloc>().add(SelectStory(item.story!));
                      }
                    },
                    onAgentTap: _navigateToAgentProfile,
                    onStartDm: _startDmWithAgent,
                  );
                },
                childCount: state.filteredItems.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow(FeedLoaded state) {
    // Group stories by agent
    final storiesByAgent = <String, List<AgentStoryDto>>{};
    for (final story in state.stories) {
      storiesByAgent.putIfAbsent(story.agentId, () => []).add(story);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: storiesByAgent.length,
          itemBuilder: (context, index) {
            final agentId = storiesByAgent.keys.elementAt(index);
            final agentStories = storiesByAgent[agentId]!;
            final hasUnviewed = agentStories.any((s) => !s.isViewed);
            final latestStory = agentStories.first;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StoryRing(
                agentId: agentId,
                displayName: latestStory.agentDisplayName ?? agentId,
                hasUnviewedStories: hasUnviewed,
                onTap: () {
                  // Select first unviewed story from this agent, or latest if all viewed
                  final storyToShow = agentStories.firstWhere(
                    (s) => !s.isViewed,
                    orElse: () => agentStories.first,
                  );
                  context.read<FeedBloc>().add(SelectStory(storyToShow));
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusesSection(FeedLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mood, color: Color(0xFF757575), size: 16),
              SizedBox(width: 8),
              Text(
                'Agent Statuses',
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
            children: state.activeStatuses.map((status) {
              return _buildStatusChip(status);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AgentStatusDto status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _getAgentColor(status.agentId),
            child: Text(
              _getAgentEmoji(status.agentId),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          if (status.mood != null) ...[
            Text(status.mood!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              status.content,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dynamic_feed,
            color: Colors.white.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No activity yet',
            style: TextStyle(color: Color(0xFF757575), fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stories and updates from agents will appear here',
            style: TextStyle(color: Color(0xFF616161), fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(FeedFilterType type) {
    switch (type) {
      case FeedFilterType.all:
        return 'All';
      case FeedFilterType.stories:
        return 'Stories';
      case FeedFilterType.statuses:
        return 'Statuses';
      case FeedFilterType.insights:
        return 'Insights';
    }
  }

  IconData _getFilterIcon(FeedFilterType type) {
    switch (type) {
      case FeedFilterType.all:
        return Icons.all_inclusive;
      case FeedFilterType.stories:
        return Icons.auto_stories;
      case FeedFilterType.statuses:
        return Icons.mood;
      case FeedFilterType.insights:
        return Icons.lightbulb_outline;
    }
  }

  void _navigateToAgentProfile(String agentId) {
    // TODO: Navigate to agent profile
  }

  void _startDmWithAgent(String agentId) {
    context.read<ConversationsBloc>().add(StartDmWithAgent(agentId));
    // TODO: Navigate to conversations
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
