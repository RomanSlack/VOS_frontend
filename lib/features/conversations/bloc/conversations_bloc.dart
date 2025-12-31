import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/core/services/social_service.dart';
import 'package:vos_app/core/services/conversation_websocket_service.dart';
import 'package:vos_app/features/conversations/bloc/conversations_event.dart';
import 'package:vos_app/features/conversations/bloc/conversations_state.dart';

final _log = Logger('ConversationsBloc');

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final SocialService _socialService;
  final ConversationWebSocketService _webSocketService;

  StreamSubscription? _webSocketMessageSubscription;
  StreamSubscription? _webSocketStateSubscription;

  ConversationsBloc(this._socialService)
      : _webSocketService = ConversationWebSocketService(),
        super(const ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<SelectConversation>(_onSelectConversation);
    on<ClearSelectedConversation>(_onClearSelectedConversation);
    on<StartDmWithAgent>(_onStartDmWithAgent);
    on<CreateGroup>(_onCreateGroup);
    on<ArchiveConversation>(_onArchiveConversation);
    on<LeaveConversation>(_onLeaveConversation);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<MessageReceived>(_onMessageReceived);
    on<ConversationUpdated>(_onConversationUpdated);
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);
    on<SendTypingIndicator>(_onSendTypingIndicator);
    on<FilterByType>(_onFilterByType);
    on<SearchConversations>(_onSearchConversations);
    on<WebSocketConnectionChanged>(_onWebSocketConnectionChanged);
    on<AgentStatusReceived>(_onAgentStatusReceived);

    // Subscribe to WebSocket events
    _subscribeToWebSocket();
  }

  void _subscribeToWebSocket() {
    // Listen for incoming messages
    _webSocketMessageSubscription = _webSocketService.messages.listen((message) {
      switch (message.type) {
        case WebSocketMessageType.newMessage:
          _handleNewMessage(message);
          break;
        case WebSocketMessageType.typingIndicator:
          _handleTypingIndicator(message);
          break;
        case WebSocketMessageType.agentStatus:
          _handleAgentStatus(message);
          break;
        case WebSocketMessageType.connected:
          _log.info('WebSocket connected to ${message.conversationId}');
          break;
        default:
          break;
      }
    });

    // Listen for connection state changes
    _webSocketStateSubscription = _webSocketService.connectionState.listen((state) {
      final isConnected = state == ConnectionState.connected;
      add(WebSocketConnectionChanged(
        isConnected: isConnected,
        conversationId: _webSocketService.currentConversationId,
      ));
    });
  }

  void _handleNewMessage(WebSocketMessage wsMessage) {
    final message = SocialMessageDto(
      messageId: wsMessage.messageId ?? '',
      conversationId: wsMessage.conversationId ?? '',
      senderType: wsMessage.senderType == 'user'
          ? ParticipantType.user
          : ParticipantType.agent,
      senderId: wsMessage.senderId ?? '',
      content: wsMessage.content ?? '',
      createdAt: wsMessage.createdAt ?? DateTime.now().toIso8601String(),
    );

    add(MessageReceived(message));
  }

  void _handleTypingIndicator(WebSocketMessage wsMessage) {
    add(TypingIndicatorReceived(
      conversationId: wsMessage.conversationId ?? '',
      userId: wsMessage.typingUserId ?? '',
      isTyping: wsMessage.isTyping,
    ));
  }

  void _handleAgentStatus(WebSocketMessage wsMessage) {
    add(AgentStatusReceived(
      conversationId: wsMessage.conversationId ?? '',
      agentId: wsMessage.agentId ?? '',
      status: wsMessage.status ?? 'idle',
      actionDescription: wsMessage.actionDescription,
    ));
  }

  @override
  Future<void> close() {
    _webSocketMessageSubscription?.cancel();
    _webSocketStateSubscription?.cancel();
    _webSocketService.dispose();
    return super.close();
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final shouldShowLoading = state is! ConversationsLoaded;
      if (shouldShowLoading) {
        emit(const ConversationsLoading());
      }

      final conversations = await _socialService.getConversations(
        type: event.filterType,
        limit: event.limit,
        offset: event.offset,
      );

      emit(ConversationsLoaded(
        conversations: conversations,
        filterType: event.filterType,
        totalCount: conversations.length,
        hasMore: conversations.length >= event.limit,
      ));
    } catch (e) {
      _log.severe('Failed to load conversations: $e');
      emit(ConversationsError('Failed to load conversations', details: e.toString()));
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    final filterType = currentState is ConversationsLoaded
        ? currentState.filterType
        : null;

    add(LoadConversations(filterType: filterType));
  }

  Future<void> _onSelectConversation(
    SelectConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      // Find or fetch the conversation
      ConversationDto? conversation = currentState.conversations
          .where((c) => c.conversationId == event.conversationId)
          .firstOrNull;

      if (conversation == null) {
        conversation = await _socialService.getConversation(event.conversationId);
      }

      emit(currentState.copyWith(
        selectedConversation: conversation,
        messages: const [],
        messagesLoading: true,
        hasMoreMessages: false,
        messageCursor: null,
        agentStatuses: const {},
      ));

      // Connect WebSocket for real-time updates
      await _webSocketService.connect(event.conversationId);

      // Load messages
      add(LoadMessages(conversationId: event.conversationId));
    } catch (e) {
      _log.severe('Failed to select conversation: $e');
      emit(ConversationsError('Failed to load conversation', details: e.toString()));
    }
  }

  Future<void> _onClearSelectedConversation(
    ClearSelectedConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    // Disconnect WebSocket
    await _webSocketService.disconnect();

    emit(currentState.copyWith(
      clearSelectedConversation: true,
      messages: const [],
      messagesLoading: false,
      isWebSocketConnected: false,
      clearConnectedConversation: true,
      agentStatuses: const {},
    ));
  }

  Future<void> _onStartDmWithAgent(
    StartDmWithAgent event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) {
      emit(const ConversationsLoading());
    }

    try {
      final dm = await _socialService.startDmWithAgent(event.agentId);

      if (currentState is ConversationsLoaded) {
        // Check if DM already exists in list
        final exists = currentState.conversations.any(
          (c) => c.conversationId == dm.conversationId,
        );

        final updatedConversations = exists
            ? currentState.conversations
            : [dm, ...currentState.conversations];

        emit(ConversationCreated(
          conversation: dm,
          previousState: currentState.copyWith(
            conversations: updatedConversations,
            selectedConversation: dm,
          ),
        ));

        // Select the DM
        add(SelectConversation(dm.conversationId));
      } else {
        add(const LoadConversations());
        add(SelectConversation(dm.conversationId));
      }
    } catch (e) {
      _log.severe('Failed to start DM: $e');
      emit(ConversationsError('Failed to start conversation', details: e.toString()));
    }
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      final group = await _socialService.createGroup(
        name: event.name,
        agentIds: event.agentIds,
        userIds: event.userIds,
      );

      final updatedConversations = [group, ...currentState.conversations];

      emit(ConversationCreated(
        conversation: group,
        previousState: currentState.copyWith(
          conversations: updatedConversations,
          selectedConversation: group,
        ),
      ));

      // Select the new group
      add(SelectConversation(group.conversationId));
    } catch (e) {
      _log.severe('Failed to create group: $e');
      emit(ConversationsError('Failed to create group', details: e.toString()));
    }
  }

  Future<void> _onArchiveConversation(
    ArchiveConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      await _socialService.archiveConversation(event.conversationId);

      final updatedConversations = currentState.conversations
          .where((c) => c.conversationId != event.conversationId)
          .toList();

      final clearSelected = currentState.selectedConversation?.conversationId ==
          event.conversationId;

      if (clearSelected) {
        await _webSocketService.disconnect();
      }

      emit(ConversationsOperationSuccess(
        message: 'Conversation archived',
        previousState: currentState.copyWith(
          conversations: updatedConversations,
          clearSelectedConversation: clearSelected,
          isWebSocketConnected: clearSelected ? false : currentState.isWebSocketConnected,
        ),
      ));
    } catch (e) {
      _log.severe('Failed to archive conversation: $e');
      emit(ConversationsError('Failed to archive conversation', details: e.toString()));
    }
  }

  Future<void> _onLeaveConversation(
    LeaveConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      await _socialService.leaveConversation(event.conversationId);

      final updatedConversations = currentState.conversations
          .where((c) => c.conversationId != event.conversationId)
          .toList();

      final clearSelected = currentState.selectedConversation?.conversationId ==
          event.conversationId;

      if (clearSelected) {
        await _webSocketService.disconnect();
      }

      emit(ConversationsOperationSuccess(
        message: 'Left conversation',
        previousState: currentState.copyWith(
          conversations: updatedConversations,
          clearSelectedConversation: clearSelected,
          isWebSocketConnected: clearSelected ? false : currentState.isWebSocketConnected,
        ),
      ));
    } catch (e) {
      _log.severe('Failed to leave conversation: $e');
      emit(ConversationsError('Failed to leave conversation', details: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    try {
      emit(currentState.copyWith(messagesLoading: true));

      final response = await _socialService.getMessages(
        event.conversationId,
        limit: event.limit,
        cursor: event.cursor,
      );

      emit(currentState.copyWith(
        messages: response.messages,
        messagesLoading: false,
        hasMoreMessages: response.hasMore,
        messageCursor: response.cursor,
      ));

      // Mark as read and send read receipt via WebSocket
      add(const MarkAsRead());
      _webSocketService.sendReadReceipt();
    } catch (e) {
      _log.severe('Failed to load messages: $e');
      emit(currentState.copyWith(messagesLoading: false));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (!currentState.hasMoreMessages || currentState.messagesLoading) return;
    if (currentState.selectedConversation == null) return;

    try {
      emit(currentState.copyWith(messagesLoading: true));

      final response = await _socialService.getMessages(
        currentState.selectedConversation!.conversationId,
        cursor: currentState.messageCursor,
      );

      emit(currentState.copyWith(
        messages: [...currentState.messages, ...response.messages],
        messagesLoading: false,
        hasMoreMessages: response.hasMore,
        messageCursor: response.cursor,
      ));
    } catch (e) {
      _log.severe('Failed to load more messages: $e');
      emit(currentState.copyWith(messagesLoading: false));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (currentState.selectedConversation == null) return;

    try {
      final message = await _socialService.sendMessage(
        currentState.selectedConversation!.conversationId,
        content: event.content,
        replyToId: event.replyToId,
        attachments: event.attachments,
      );

      // Add message to the list optimistically
      final updatedMessages = [message, ...currentState.messages];

      emit(MessageSent(
        message: message,
        previousState: currentState.copyWith(messages: updatedMessages),
      ));

      // Stop typing indicator
      _webSocketService.sendTypingIndicator(false);
    } catch (e) {
      _log.severe('Failed to send message: $e');
      emit(ConversationsError('Failed to send message', details: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (currentState.selectedConversation == null) return;

    try {
      await _socialService.markAsRead(
        currentState.selectedConversation!.conversationId,
      );

      // Update unread count locally
      final updatedConversations = currentState.conversations.map((c) {
        if (c.conversationId == currentState.selectedConversation!.conversationId) {
          return ConversationDto(
            conversationId: c.conversationId,
            conversationType: c.conversationType,
            name: c.name,
            createdByType: c.createdByType,
            createdById: c.createdById,
            createdAt: c.createdAt,
            lastMessageAt: c.lastMessageAt,
            lastMessagePreview: c.lastMessagePreview,
            isArchived: c.isArchived,
            participants: c.participants,
            unreadCount: 0,
          );
        }
        return c;
      }).toList();

      emit(currentState.copyWith(conversations: updatedConversations));
    } catch (e) {
      // Non-critical, just log
      _log.warning('Failed to mark as read: $e');
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    // Check if message is for the selected conversation
    if (currentState.selectedConversation?.conversationId ==
        event.message.conversationId) {
      // Add to messages list
      final updatedMessages = [event.message, ...currentState.messages];
      emit(currentState.copyWith(messages: updatedMessages));

      // Mark as read since we're viewing this conversation
      add(const MarkAsRead());
      _webSocketService.sendReadReceipt();
    } else {
      // Update unread count for the conversation
      final updatedConversations = currentState.conversations.map((c) {
        if (c.conversationId == event.message.conversationId) {
          return ConversationDto(
            conversationId: c.conversationId,
            conversationType: c.conversationType,
            name: c.name,
            createdByType: c.createdByType,
            createdById: c.createdById,
            createdAt: c.createdAt,
            lastMessageAt: event.message.createdAt,
            lastMessagePreview: event.message.content.length > 50
                ? '${event.message.content.substring(0, 50)}...'
                : event.message.content,
            isArchived: c.isArchived,
            participants: c.participants,
            unreadCount: c.unreadCount + 1,
          );
        }
        return c;
      }).toList();

      emit(currentState.copyWith(conversations: updatedConversations));
    }
  }

  void _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    final updatedConversations = currentState.conversations.map((c) {
      if (c.conversationId == event.conversation.conversationId) {
        return event.conversation;
      }
      return c;
    }).toList();

    // Also update selected conversation if it's the same
    ConversationDto? updatedSelected = currentState.selectedConversation;
    if (updatedSelected?.conversationId == event.conversation.conversationId) {
      updatedSelected = event.conversation;
    }

    emit(currentState.copyWith(
      conversations: updatedConversations,
      selectedConversation: updatedSelected,
    ));
  }

  void _onTypingIndicatorReceived(
    TypingIndicatorReceived event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (currentState.selectedConversation?.conversationId !=
        event.conversationId) return;

    final updatedTyping = Map<String, bool>.from(currentState.typingUsers);
    if (event.isTyping) {
      updatedTyping[event.userId] = true;
    } else {
      updatedTyping.remove(event.userId);
    }

    emit(currentState.copyWith(typingUsers: updatedTyping));
  }

  void _onSendTypingIndicator(
    SendTypingIndicator event,
    Emitter<ConversationsState> emit,
  ) {
    _webSocketService.sendTypingIndicator(event.isTyping);
  }

  void _onWebSocketConnectionChanged(
    WebSocketConnectionChanged event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    emit(currentState.copyWith(
      isWebSocketConnected: event.isConnected,
      connectedConversationId: event.conversationId,
    ));
  }

  void _onAgentStatusReceived(
    AgentStatusReceived event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (currentState.selectedConversation?.conversationId !=
        event.conversationId) return;

    final updatedStatuses = Map<String, AgentStatusInfo>.from(currentState.agentStatuses);

    if (event.status == 'idle') {
      updatedStatuses.remove(event.agentId);
    } else {
      updatedStatuses[event.agentId] = AgentStatusInfo(
        agentId: event.agentId,
        status: event.status,
        actionDescription: event.actionDescription,
        timestamp: DateTime.now(),
      );
    }

    emit(currentState.copyWith(agentStatuses: updatedStatuses));
  }

  Future<void> _onFilterByType(
    FilterByType event,
    Emitter<ConversationsState> emit,
  ) async {
    add(LoadConversations(filterType: event.type));
  }

  Future<void> _onSearchConversations(
    SearchConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    if (event.query.isEmpty) {
      // Clear search
      add(const RefreshConversations());
      return;
    }

    // Filter locally for now (could be server-side later)
    final filtered = currentState.conversations.where((c) {
      final name = c.name?.toLowerCase() ?? '';
      final query = event.query.toLowerCase();

      return name.contains(query) ||
          c.conversationId.toLowerCase().contains(query) ||
          c.participants.any((p) =>
              p.participantId.toLowerCase().contains(query));
    }).toList();

    emit(currentState.copyWith(
      conversations: filtered,
      searchQuery: event.query,
    ));
  }
}
