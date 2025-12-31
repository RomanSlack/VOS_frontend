import 'package:json_annotation/json_annotation.dart';

part 'social_models.g.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum ConversationType {
  @JsonValue('main')
  main,
  @JsonValue('dm')
  dm,
  @JsonValue('group')
  group,
  @JsonValue('agent_chat')
  agentChat,
}

enum ParticipantType {
  @JsonValue('user')
  user,
  @JsonValue('agent')
  agent,
}

enum ParticipantRole {
  @JsonValue('member')
  member,
  @JsonValue('admin')
  admin,
  @JsonValue('observer')
  observer,
}

enum StoryType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('task_completion')
  taskCompletion,
  @JsonValue('insight')
  insight,
}

enum ReportType {
  @JsonValue('conversation_end')
  conversationEnd,
  @JsonValue('escalation')
  escalation,
  @JsonValue('error')
  error,
  @JsonValue('daily_summary')
  dailySummary,
}

enum ReportPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

// =============================================================================
// CONVERSATION MODELS
// =============================================================================

@JsonSerializable()
class ConversationParticipantDto {
  @JsonKey(name: 'participant_type')
  final ParticipantType participantType;
  @JsonKey(name: 'participant_id')
  final String participantId;
  final ParticipantRole role;
  @JsonKey(name: 'joined_at')
  final String? joinedAt;
  @JsonKey(name: 'last_read_at')
  final String? lastReadAt;

  const ConversationParticipantDto({
    required this.participantType,
    required this.participantId,
    this.role = ParticipantRole.member,
    this.joinedAt,
    this.lastReadAt,
  });

  factory ConversationParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationParticipantDtoToJson(this);
}

@JsonSerializable()
class ConversationDto {
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'conversation_type')
  final ConversationType conversationType;
  final String? name;
  @JsonKey(name: 'created_by_type')
  final String createdByType;
  @JsonKey(name: 'created_by_id')
  final String createdById;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'last_message_at')
  final String? lastMessageAt;
  @JsonKey(name: 'last_message_preview')
  final String? lastMessagePreview;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  final List<ConversationParticipantDto> participants;
  @JsonKey(name: 'unread_count')
  final int unreadCount;

  const ConversationDto({
    required this.conversationId,
    required this.conversationType,
    this.name,
    required this.createdByType,
    required this.createdById,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.isArchived = false,
    required this.participants,
    this.unreadCount = 0,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);

  /// Get display name for the conversation
  String getDisplayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) return name!;

    if (conversationType == ConversationType.dm) {
      // For DMs, show the other participant's name
      final other = participants.firstWhere(
        (p) => p.participantId != currentUserId,
        orElse: () => participants.first,
      );
      return other.participantId;
    }

    return conversationId;
  }

  /// Check if this is a DM with a specific agent
  bool isDmWithAgent(String agentId) {
    return conversationType == ConversationType.dm &&
        participants.any(
          (p) => p.participantType == ParticipantType.agent &&
                 p.participantId == agentId,
        );
  }
}

@JsonSerializable()
class ConversationListResponseDto {
  final List<ConversationDto> conversations;
  @JsonKey(name: 'total_count')
  final int totalCount;
  final int limit;
  final int offset;

  const ConversationListResponseDto({
    required this.conversations,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  factory ConversationListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationListResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationListResponseDtoToJson(this);
}

@JsonSerializable()
class CreateConversationRequestDto {
  @JsonKey(name: 'conversation_type')
  final ConversationType conversationType;
  final String? name;
  final List<ConversationParticipantDto> participants;

  const CreateConversationRequestDto({
    required this.conversationType,
    this.name,
    required this.participants,
  });

  factory CreateConversationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateConversationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateConversationRequestDtoToJson(this);
}

// =============================================================================
// CONVERSATION MESSAGE MODELS
// =============================================================================

@JsonSerializable()
class SocialMessageDto {
  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_type')
  final ParticipantType senderType;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'reply_to_id')
  final String? replyToId;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;

  const SocialMessageDto({
    required this.messageId,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.content,
    this.contentType = 'text',
    required this.createdAt,
    this.replyToId,
    this.attachments,
    this.metadata,
  });

  factory SocialMessageDto.fromJson(Map<String, dynamic> json) =>
      _$SocialMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialMessageDtoToJson(this);
}

@JsonSerializable()
class MessageListResponseDto {
  final List<SocialMessageDto> messages;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  final String? cursor;

  const MessageListResponseDto({
    required this.messages,
    required this.totalCount,
    required this.hasMore,
    this.cursor,
  });

  factory MessageListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageListResponseDtoToJson(this);
}

@JsonSerializable()
class SendMessageRequestDto {
  final String content;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'reply_to_id')
  final String? replyToId;
  final List<String>? attachments;

  const SendMessageRequestDto({
    required this.content,
    this.contentType = 'text',
    this.replyToId,
    this.attachments,
  });

  factory SendMessageRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestDtoToJson(this);
}

// =============================================================================
// AGENT PROFILE & HEALTH MODELS
// =============================================================================

@JsonSerializable()
class AgentProfileDto {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? description;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_seen')
  final String? lastSeen;
  @JsonKey(name: 'current_status')
  final AgentStatusDto? currentStatus;
  final List<String>? capabilities;

  const AgentProfileDto({
    required this.agentId,
    required this.displayName,
    this.description,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.currentStatus,
    this.capabilities,
  });

  factory AgentProfileDto.fromJson(Map<String, dynamic> json) =>
      _$AgentProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentProfileDtoToJson(this);
}

@JsonSerializable()
class AgentHealthDto {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_heartbeat')
  final String? lastHeartbeat;
  @JsonKey(name: 'started_at')
  final String? startedAt;
  @JsonKey(name: 'crash_count')
  final int crashCount;
  @JsonKey(name: 'last_crash_reason')
  final String? lastCrashReason;
  @JsonKey(name: 'last_crash_at')
  final String? lastCrashAt;

  const AgentHealthDto({
    required this.agentId,
    required this.isOnline,
    this.lastHeartbeat,
    this.startedAt,
    this.crashCount = 0,
    this.lastCrashReason,
    this.lastCrashAt,
  });

  factory AgentHealthDto.fromJson(Map<String, dynamic> json) =>
      _$AgentHealthDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentHealthDtoToJson(this);
}

@JsonSerializable()
class AgentListResponseDto {
  final List<AgentProfileDto> agents;
  @JsonKey(name: 'online_count')
  final int onlineCount;
  @JsonKey(name: 'total_count')
  final int totalCount;

  const AgentListResponseDto({
    required this.agents,
    required this.onlineCount,
    required this.totalCount,
  });

  factory AgentListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentListResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentListResponseDtoToJson(this);
}

// =============================================================================
// FEED MODELS (STATUSES & STORIES)
// =============================================================================

@JsonSerializable()
class AgentStatusDto {
  @JsonKey(name: 'status_id')
  final String statusId;
  @JsonKey(name: 'agent_id')
  final String agentId;
  final String content;
  final String? mood;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'expires_at')
  final String expiresAt;

  const AgentStatusDto({
    required this.statusId,
    required this.agentId,
    required this.content,
    this.mood,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AgentStatusDto.fromJson(Map<String, dynamic> json) =>
      _$AgentStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentStatusDtoToJson(this);

  bool get isExpired => DateTime.parse(expiresAt).isBefore(DateTime.now());
}

@JsonSerializable()
class AgentStoryDto {
  @JsonKey(name: 'story_id')
  final String storyId;
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'story_type')
  final StoryType storyType;
  final String? title;
  final String content;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'is_viewed')
  final bool isViewed;

  const AgentStoryDto({
    required this.storyId,
    required this.agentId,
    required this.storyType,
    this.title,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isViewed = false,
  });

  factory AgentStoryDto.fromJson(Map<String, dynamic> json) =>
      _$AgentStoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentStoryDtoToJson(this);

  bool get isExpired => DateTime.parse(expiresAt).isBefore(DateTime.now());
}

@JsonSerializable()
class FeedResponseDto {
  final List<AgentStatusDto> statuses;
  final List<AgentStoryDto> stories;
  @JsonKey(name: 'has_more')
  final bool hasMore;

  const FeedResponseDto({
    required this.statuses,
    required this.stories,
    this.hasMore = false,
  });

  factory FeedResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FeedResponseDtoToJson(this);
}

// =============================================================================
// WEBSOCKET NOTIFICATION PAYLOADS (for real-time updates)
// =============================================================================

@JsonSerializable()
class ConversationMessagePayload {
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'sender_type')
  final String senderType;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(name: 'content_type')
  final String contentType;
  final String timestamp;
  @JsonKey(name: 'reply_to_id')
  final String? replyToId;

  const ConversationMessagePayload({
    required this.conversationId,
    required this.messageId,
    required this.senderType,
    required this.senderId,
    required this.content,
    this.contentType = 'text',
    required this.timestamp,
    this.replyToId,
  });

  factory ConversationMessagePayload.fromJson(Map<String, dynamic> json) =>
      _$ConversationMessagePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationMessagePayloadToJson(this);
}

@JsonSerializable()
class AgentHealthUpdatePayload {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_heartbeat')
  final String? lastHeartbeat;
  @JsonKey(name: 'crash_reason')
  final String? crashReason;
  final String timestamp;

  const AgentHealthUpdatePayload({
    required this.agentId,
    required this.isOnline,
    this.lastHeartbeat,
    this.crashReason,
    required this.timestamp,
  });

  factory AgentHealthUpdatePayload.fromJson(Map<String, dynamic> json) =>
      _$AgentHealthUpdatePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AgentHealthUpdatePayloadToJson(this);
}

@JsonSerializable()
class TypingIndicatorPayload {
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'is_typing')
  final bool isTyping;
  final String timestamp;

  const TypingIndicatorPayload({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingIndicatorPayload.fromJson(Map<String, dynamic> json) =>
      _$TypingIndicatorPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TypingIndicatorPayloadToJson(this);
}

@JsonSerializable()
class FeedStatusPayload {
  @JsonKey(name: 'status_id')
  final String statusId;
  @JsonKey(name: 'agent_id')
  final String agentId;
  final String content;
  final String? mood;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  final String timestamp;

  const FeedStatusPayload({
    required this.statusId,
    required this.agentId,
    required this.content,
    this.mood,
    required this.expiresAt,
    required this.timestamp,
  });

  factory FeedStatusPayload.fromJson(Map<String, dynamic> json) =>
      _$FeedStatusPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$FeedStatusPayloadToJson(this);
}

@JsonSerializable()
class FeedStoryPayload {
  @JsonKey(name: 'story_id')
  final String storyId;
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'story_type')
  final String storyType;
  final String? title;
  final String content;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  final String timestamp;

  const FeedStoryPayload({
    required this.storyId,
    required this.agentId,
    required this.storyType,
    this.title,
    required this.content,
    this.mediaUrl,
    required this.expiresAt,
    required this.timestamp,
  });

  factory FeedStoryPayload.fromJson(Map<String, dynamic> json) =>
      _$FeedStoryPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$FeedStoryPayloadToJson(this);
}
