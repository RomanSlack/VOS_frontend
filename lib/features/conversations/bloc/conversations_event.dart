import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all conversations for the current user
class LoadConversations extends ConversationsEvent {
  final ConversationType? filterType;
  final int limit;
  final int offset;

  const LoadConversations({
    this.filterType,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [filterType, limit, offset];
}

/// Refresh conversations list
class RefreshConversations extends ConversationsEvent {
  const RefreshConversations();
}

/// Select a conversation to view
class SelectConversation extends ConversationsEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Clear selected conversation
class ClearSelectedConversation extends ConversationsEvent {
  const ClearSelectedConversation();
}

/// Start a DM with an agent
class StartDmWithAgent extends ConversationsEvent {
  final String agentId;

  const StartDmWithAgent(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

/// Create a new group
class CreateGroup extends ConversationsEvent {
  final String name;
  final List<String> agentIds;
  final List<String>? userIds;

  const CreateGroup({
    required this.name,
    required this.agentIds,
    this.userIds,
  });

  @override
  List<Object?> get props => [name, agentIds, userIds];
}

/// Archive a conversation
class ArchiveConversation extends ConversationsEvent {
  final String conversationId;

  const ArchiveConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Leave a conversation
class LeaveConversation extends ConversationsEvent {
  final String conversationId;

  const LeaveConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Load messages for the selected conversation
class LoadMessages extends ConversationsEvent {
  final String conversationId;
  final int limit;
  final String? cursor;

  const LoadMessages({
    required this.conversationId,
    this.limit = 50,
    this.cursor,
  });

  @override
  List<Object?> get props => [conversationId, limit, cursor];
}

/// Load more messages (pagination)
class LoadMoreMessages extends ConversationsEvent {
  const LoadMoreMessages();
}

/// Send a message to the current conversation
class SendMessage extends ConversationsEvent {
  final String content;
  final String? replyToId;
  final List<String>? attachments;

  const SendMessage({
    required this.content,
    this.replyToId,
    this.attachments,
  });

  @override
  List<Object?> get props => [content, replyToId, attachments];
}

/// Mark current conversation as read
class MarkAsRead extends ConversationsEvent {
  const MarkAsRead();
}

/// New message received via WebSocket
class MessageReceived extends ConversationsEvent {
  final SocialMessageDto message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Conversation updated via WebSocket
class ConversationUpdated extends ConversationsEvent {
  final ConversationDto conversation;

  const ConversationUpdated(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

/// Typing indicator received
class TypingIndicatorReceived extends ConversationsEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const TypingIndicatorReceived({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

/// Send typing indicator
class SendTypingIndicator extends ConversationsEvent {
  final bool isTyping;

  const SendTypingIndicator(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

/// Filter conversations by type
class FilterByType extends ConversationsEvent {
  final ConversationType? type;

  const FilterByType(this.type);

  @override
  List<Object?> get props => [type];
}

/// Search conversations
class SearchConversations extends ConversationsEvent {
  final String query;

  const SearchConversations(this.query);

  @override
  List<Object?> get props => [query];
}

/// WebSocket connection state changed
class WebSocketConnectionChanged extends ConversationsEvent {
  final bool isConnected;
  final String? conversationId;

  const WebSocketConnectionChanged({
    required this.isConnected,
    this.conversationId,
  });

  @override
  List<Object?> get props => [isConnected, conversationId];
}

/// Agent status update received
class AgentStatusReceived extends ConversationsEvent {
  final String conversationId;
  final String agentId;
  final String status;
  final String? actionDescription;

  const AgentStatusReceived({
    required this.conversationId,
    required this.agentId,
    required this.status,
    this.actionDescription,
  });

  @override
  List<Object?> get props => [conversationId, agentId, status, actionDescription];
}
