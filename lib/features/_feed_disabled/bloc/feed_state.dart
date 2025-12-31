import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/feed/bloc/feed_event.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FeedInitial extends FeedState {
  const FeedInitial();
}

/// Loading feed
class FeedLoading extends FeedState {
  const FeedLoading();
}

/// Feed loaded successfully
class FeedLoaded extends FeedState {
  final List<FeedItemDto> items;
  final List<AgentStoryDto> stories;
  final List<AgentStatusDto> statuses;
  final FeedFilterType filterType;
  final bool hasMore;
  final bool isLoadingMore;
  final AgentStoryDto? selectedStory;
  final int selectedStoryIndex;
  final List<AgentStoryDto> storyQueue; // Stories in viewing order

  const FeedLoaded({
    required this.items,
    this.stories = const [],
    this.statuses = const [],
    this.filterType = FeedFilterType.all,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.selectedStory,
    this.selectedStoryIndex = -1,
    this.storyQueue = const [],
  });

  @override
  List<Object?> get props => [
        items,
        stories,
        statuses,
        filterType,
        hasMore,
        isLoadingMore,
        selectedStory,
        selectedStoryIndex,
        storyQueue,
      ];

  FeedLoaded copyWith({
    List<FeedItemDto>? items,
    List<AgentStoryDto>? stories,
    List<AgentStatusDto>? statuses,
    FeedFilterType? filterType,
    bool? hasMore,
    bool? isLoadingMore,
    AgentStoryDto? selectedStory,
    bool clearSelectedStory = false,
    int? selectedStoryIndex,
    List<AgentStoryDto>? storyQueue,
  }) {
    return FeedLoaded(
      items: items ?? this.items,
      stories: stories ?? this.stories,
      statuses: statuses ?? this.statuses,
      filterType: filterType ?? this.filterType,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedStory: clearSelectedStory ? null : (selectedStory ?? this.selectedStory),
      selectedStoryIndex: clearSelectedStory ? -1 : (selectedStoryIndex ?? this.selectedStoryIndex),
      storyQueue: storyQueue ?? this.storyQueue,
    );
  }

  /// Get filtered items based on current filter
  List<FeedItemDto> get filteredItems {
    switch (filterType) {
      case FeedFilterType.all:
        return items;
      case FeedFilterType.stories:
        return items.where((i) => i.itemType == FeedItemType.story).toList();
      case FeedFilterType.statuses:
        return items.where((i) => i.itemType == FeedItemType.status).toList();
      case FeedFilterType.insights:
        return items.where((i) =>
          i.story?.storyType == StoryType.insight ||
          i.story?.storyType == StoryType.taskCompletion
        ).toList();
    }
  }

  /// Get unviewed stories count
  int get unviewedStoriesCount => stories.where((s) => !s.isViewed).length;

  /// Get active statuses (agents with statuses)
  List<AgentStatusDto> get activeStatuses =>
      statuses.where((s) => s.content.isNotEmpty).toList();

  /// Check if there are stories to view
  bool get hasUnviewedStories => stories.any((s) => !s.isViewed);

  /// Can navigate to next story
  bool get canGoNext =>
      selectedStory != null && selectedStoryIndex < storyQueue.length - 1;

  /// Can navigate to previous story
  bool get canGoPrevious =>
      selectedStory != null && selectedStoryIndex > 0;
}

/// Error state
class FeedError extends FeedState {
  final String message;
  final String? details;

  const FeedError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}
