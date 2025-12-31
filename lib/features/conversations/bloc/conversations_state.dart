import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading
class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

/// Loading conversations list
class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// Conversations loaded successfully
class ConversationsLoaded extends ConversationsState {
  final List<ConversationDto> conversations;
  final ConversationType? filterType;
  final int totalCount;
  final bool hasMore;
  final String? searchQuery;

  // Selected conversation state
  final ConversationDto? selectedConversation;
  final List<SocialMessageDto> messages;
  final bool messagesLoading;
  final bool hasMoreMessages;
  final String? messageCursor;
  final Map<String, bool> typingUsers; // participantId -> isTyping

  // WebSocket connection state
  final bool isWebSocketConnected;
  final String? connectedConversationId;

  // Agent status in current conversation
  final Map<String, AgentStatusInfo> agentStatuses; // agentId -> status

  const ConversationsLoaded({
    required this.conversations,
    this.filterType,
    this.totalCount = 0,
    this.hasMore = false,
    this.searchQuery,
    this.selectedConversation,
    this.messages = const [],
    this.messagesLoading = false,
    this.hasMoreMessages = false,
    this.messageCursor,
    this.typingUsers = const {},
    this.isWebSocketConnected = false,
    this.connectedConversationId,
    this.agentStatuses = const {},
  });

  @override
  List<Object?> get props => [
        conversations,
        filterType,
        totalCount,
        hasMore,
        searchQuery,
        selectedConversation,
        messages,
        messagesLoading,
        hasMoreMessages,
        messageCursor,
        typingUsers,
        isWebSocketConnected,
        connectedConversationId,
        agentStatuses,
      ];

  ConversationsLoaded copyWith({
    List<ConversationDto>? conversations,
    ConversationType? filterType,
    bool clearFilter = false,
    int? totalCount,
    bool? hasMore,
    String? searchQuery,
    bool clearSearchQuery = false,
    ConversationDto? selectedConversation,
    bool clearSelectedConversation = false,
    List<SocialMessageDto>? messages,
    bool? messagesLoading,
    bool? hasMoreMessages,
    String? messageCursor,
    Map<String, bool>? typingUsers,
    bool? isWebSocketConnected,
    String? connectedConversationId,
    bool clearConnectedConversation = false,
    Map<String, AgentStatusInfo>? agentStatuses,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      selectedConversation: clearSelectedConversation
          ? null
          : (selectedConversation ?? this.selectedConversation),
      messages: messages ?? this.messages,
      messagesLoading: messagesLoading ?? this.messagesLoading,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      messageCursor: messageCursor ?? this.messageCursor,
      typingUsers: typingUsers ?? this.typingUsers,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      connectedConversationId: clearConnectedConversation
          ? null
          : (connectedConversationId ?? this.connectedConversationId),
      agentStatuses: agentStatuses ?? this.agentStatuses,
    );
  }

  /// Get DMs only
  List<ConversationDto> get dms =>
      conversations.where((c) => c.conversationType == ConversationType.dm).toList();

  /// Get groups only
  List<ConversationDto> get groups =>
      conversations.where((c) => c.conversationType == ConversationType.group).toList();

  /// Get agent chats only
  List<ConversationDto> get agentChats =>
      conversations.where((c) => c.conversationType == ConversationType.agentChat).toList();

  /// Get total unread count
  int get totalUnreadCount =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Check if a conversation is selected
  bool get hasSelectedConversation => selectedConversation != null;
}

/// Error state
class ConversationsError extends ConversationsState {
  final String message;
  final String? details;

  const ConversationsError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}

/// Operation success (transient state for notifications)
class ConversationsOperationSuccess extends ConversationsState {
  final String message;
  final ConversationsLoaded previousState;

  const ConversationsOperationSuccess({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

/// New conversation created
class ConversationCreated extends ConversationsState {
  final ConversationDto conversation;
  final ConversationsLoaded previousState;

  const ConversationCreated({
    required this.conversation,
    required this.previousState,
  });

  @override
  List<Object?> get props => [conversation, previousState];
}

/// Message sent successfully
class MessageSent extends ConversationsState {
  final SocialMessageDto message;
  final ConversationsLoaded previousState;

  const MessageSent({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

/// Agent status information
class AgentStatusInfo extends Equatable {
  final String agentId;
  final String status; // thinking, executing_tools, idle
  final String? actionDescription;
  final DateTime timestamp;

  const AgentStatusInfo({
    required this.agentId,
    required this.status,
    this.actionDescription,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [agentId, status, actionDescription, timestamp];

  bool get isActive => status != 'idle';
  bool get isThinking => status == 'thinking';
  bool get isExecutingTools => status == 'executing_tools';
}
