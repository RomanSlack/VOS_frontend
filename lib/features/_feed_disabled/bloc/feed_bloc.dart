import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/core/services/social_service.dart';
import 'package:vos_app/features/feed/bloc/feed_event.dart';
import 'package:vos_app/features/feed/bloc/feed_state.dart';

final _log = Logger('FeedBloc');

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final SocialService _socialService;

  FeedBloc(this._socialService) : super(const FeedInitial()) {
    on<LoadFeed>(_onLoadFeed);
    on<RefreshFeed>(_onRefreshFeed);
    on<LoadMoreFeed>(_onLoadMoreFeed);
    on<StoryPosted>(_onStoryPosted);
    on<AgentStatusUpdated>(_onAgentStatusUpdated);
    on<MarkStoryViewed>(_onMarkStoryViewed);
    on<FilterFeed>(_onFilterFeed);
    on<SelectStory>(_onSelectStory);
    on<ClearSelectedStory>(_onClearSelectedStory);
    on<NextStory>(_onNextStory);
    on<PreviousStory>(_onPreviousStory);
  }

  Future<void> _onLoadFeed(
    LoadFeed event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final shouldShowLoading = state is! FeedLoaded;
      if (shouldShowLoading) {
        emit(const FeedLoading());
      }

      final response = await _socialService.getFeed(limit: event.limit);

      emit(FeedLoaded(
        items: response.items,
        stories: response.recentStories,
        statuses: response.agentStatuses,
        hasMore: response.items.length >= event.limit,
      ));
    } catch (e) {
      _log.severe('Failed to load feed: $e');
      emit(FeedError('Failed to load feed', details: e.toString()));
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    add(const LoadFeed());
  }

  Future<void> _onLoadMoreFeed(
    LoadMoreFeed event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final response = await _socialService.getFeed(
        limit: 50,
        beforeId: currentState.items.isNotEmpty ? currentState.items.last.id : null,
      );

      emit(currentState.copyWith(
        items: [...currentState.items, ...response.items],
        hasMore: response.items.length >= 50,
        isLoadingMore: false,
      ));
    } catch (e) {
      _log.severe('Failed to load more feed items: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onStoryPosted(
    StoryPosted event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Add new story to the beginning
    final updatedStories = [event.story, ...currentState.stories];

    // Also add as a feed item
    final newFeedItem = FeedItemDto(
      id: 'feed_${event.story.storyId}',
      agentId: event.story.agentId,
      agentDisplayName: event.story.agentDisplayName,
      itemType: FeedItemType.story,
      story: event.story,
      createdAt: event.story.createdAt,
    );

    emit(currentState.copyWith(
      stories: updatedStories,
      items: [newFeedItem, ...currentState.items],
    ));
  }

  void _onAgentStatusUpdated(
    AgentStatusUpdated event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Update or add the agent's status
    final updatedStatuses = currentState.statuses.map((status) {
      if (status.agentId == event.agentId) {
        return event.status;
      }
      return status;
    }).toList();

    // If agent wasn't in the list, add them
    if (!updatedStatuses.any((s) => s.agentId == event.agentId)) {
      updatedStatuses.add(event.status);
    }

    emit(currentState.copyWith(statuses: updatedStatuses));
  }

  Future<void> _onMarkStoryViewed(
    MarkStoryViewed event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    try {
      // Optimistically update local state
      final updatedStories = currentState.stories.map((story) {
        if (story.storyId == event.storyId) {
          return AgentStoryDto(
            storyId: story.storyId,
            agentId: story.agentId,
            agentDisplayName: story.agentDisplayName,
            storyType: story.storyType,
            content: story.content,
            title: story.title,
            mediaUrl: story.mediaUrl,
            metadata: story.metadata,
            expiresAt: story.expiresAt,
            createdAt: story.createdAt,
            viewCount: story.viewCount + 1,
            isViewed: true,
          );
        }
        return story;
      }).toList();

      emit(currentState.copyWith(stories: updatedStories));

      // Call API to mark as viewed
      await _socialService.markStoryViewed(event.storyId);
    } catch (e) {
      _log.warning('Failed to mark story as viewed: $e');
      // Don't revert - not critical
    }
  }

  void _onFilterFeed(
    FilterFeed event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    emit(currentState.copyWith(filterType: event.filterType));
  }

  void _onSelectStory(
    SelectStory event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Build story queue starting from the selected story
    final allStories = currentState.stories;
    final storyIndex = allStories.indexWhere((s) => s.storyId == event.story.storyId);

    if (storyIndex == -1) {
      // Story not in list, just show it
      emit(currentState.copyWith(
        selectedStory: event.story,
        selectedStoryIndex: 0,
        storyQueue: [event.story],
      ));
    } else {
      emit(currentState.copyWith(
        selectedStory: event.story,
        selectedStoryIndex: storyIndex,
        storyQueue: allStories,
      ));
    }

    // Mark as viewed
    add(MarkStoryViewed(event.story.storyId));
  }

  void _onClearSelectedStory(
    ClearSelectedStory event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    emit(currentState.copyWith(clearSelectedStory: true));
  }

  void _onNextStory(
    NextStory event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded || !currentState.canGoNext) return;

    final nextIndex = currentState.selectedStoryIndex + 1;
    final nextStory = currentState.storyQueue[nextIndex];

    emit(currentState.copyWith(
      selectedStory: nextStory,
      selectedStoryIndex: nextIndex,
    ));

    // Mark as viewed
    add(MarkStoryViewed(nextStory.storyId));
  }

  void _onPreviousStory(
    PreviousStory event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is! FeedLoaded || !currentState.canGoPrevious) return;

    final prevIndex = currentState.selectedStoryIndex - 1;
    final prevStory = currentState.storyQueue[prevIndex];

    emit(currentState.copyWith(
      selectedStory: prevStory,
      selectedStoryIndex: prevIndex,
    ));
  }
}
