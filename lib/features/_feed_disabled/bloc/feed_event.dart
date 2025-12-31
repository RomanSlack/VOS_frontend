import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial feed
class LoadFeed extends FeedEvent {
  final int limit;

  const LoadFeed({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

/// Refresh feed
class RefreshFeed extends FeedEvent {
  const RefreshFeed();
}

/// Load more feed items (pagination)
class LoadMoreFeed extends FeedEvent {
  const LoadMoreFeed();
}

/// New story posted by an agent (real-time update)
class StoryPosted extends FeedEvent {
  final AgentStoryDto story;

  const StoryPosted(this.story);

  @override
  List<Object?> get props => [story];
}

/// Agent status updated (real-time update)
class AgentStatusUpdated extends FeedEvent {
  final String agentId;
  final AgentStatusDto status;

  const AgentStatusUpdated(this.agentId, this.status);

  @override
  List<Object?> get props => [agentId, status];
}

/// Mark story as viewed
class MarkStoryViewed extends FeedEvent {
  final String storyId;

  const MarkStoryViewed(this.storyId);

  @override
  List<Object?> get props => [storyId];
}

/// Filter feed by type
class FilterFeed extends FeedEvent {
  final FeedFilterType filterType;

  const FilterFeed(this.filterType);

  @override
  List<Object?> get props => [filterType];
}

/// Select a story to view in detail
class SelectStory extends FeedEvent {
  final AgentStoryDto story;

  const SelectStory(this.story);

  @override
  List<Object?> get props => [story];
}

/// Clear selected story
class ClearSelectedStory extends FeedEvent {
  const ClearSelectedStory();
}

/// Navigate to next story in feed
class NextStory extends FeedEvent {
  const NextStory();
}

/// Navigate to previous story in feed
class PreviousStory extends FeedEvent {
  const PreviousStory();
}

enum FeedFilterType {
  all,
  stories,
  statuses,
  insights,
}
