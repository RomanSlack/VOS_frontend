import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/services/websocket_service.dart';
import 'package:vos_app/utils/timestamp_formatter.dart';
import 'package:vos_app/utils/chat_toast.dart';
import 'package:vos_app/presentation/widgets/audio_player_widget.dart';

class ChatApp extends StatefulWidget {
  final ChatManager chatManager;
  final ChatService chatService;
  final ValueNotifier<String?> statusNotifier;
  final ValueNotifier<bool> isActiveNotifier;
  final ValueNotifier<bool> autoPlayAudioNotifier;

  const ChatApp({
    super.key,
    required this.chatManager,
    required this.chatService,
    required this.statusNotifier,
    required this.isActiveNotifier,
    required this.autoPlayAudioNotifier,
  });

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  String? _lastProcessedMessage;
  int _lastMessageCount = 0;
  bool _isLoadingHistory = true;
  String? _historyError;
  bool _isUserAtBottom = true;
  bool _showScrollToBottom = false;
  Timer? _scrollDebounceTimer;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.connected;
  StreamSubscription? _connectionStateSubscription;

  // Cache processed messages to avoid expensive recalculation on every build
  List<_MessageWithDate>? _cachedProcessedMessages;
  int _cachedMessageCount = 0;

  @override
  void initState() {
    super.initState();

    // Load conversation history first
    _loadConversationHistory();

    // Initialize WebSocket connection
    widget.chatService.initializeWebSocket(
      chatManager: widget.chatManager,
    );

    // Listen for changes and trigger AI responses for new user messages
    widget.chatManager.addListener(_onChatManagerChanged);

    // Subscribe to action status updates
    widget.chatService.actionStream.listen((actionPayload) {
      widget.statusNotifier.value = actionPayload.actionDescription;
    });

    // Subscribe to agent status updates (for animation control)
    widget.chatService.statusStream.listen((statusPayload) {
      final state = statusPayload.processingState?.toLowerCase();
      final isThinking = state == 'thinking';
      final isExecuting = state == 'executing_tools';

      widget.isActiveNotifier.value = isThinking || isExecuting;


      // Keep status message visible even when agent goes idle
      // so users can see the last action that was performed
    });

    // Subscribe to connection state changes
    _connectionStateSubscription = widget.chatService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
        widget.chatManager.setConnectionStatus(
          state == WebSocketConnectionState.connected
        );
      }
    });

    // Listen to scroll position
    _itemPositionsListener.itemPositions.addListener(_onScroll);

    // Initialize message count
    _lastMessageCount = widget.chatManager.messages.length;

    // Check if there's a new user message that needs AI response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewUserMessage();
    });
  }

  @override
  void dispose() {
    widget.chatManager.removeListener(_onChatManagerChanged);
    _scrollDebounceTimer?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversationHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      // Preserve any pending messages before loading history
      final pendingMessages = widget.chatManager.messages
          .where((m) => m.status == MessageStatus.sending)
          .toList();

      final messages = await widget.chatService.loadConversationHistory();
      if (mounted) {
        // Load messages and preserve pending ones
        widget.chatManager.loadMessages(messages, pendingMessages: pendingMessages);

        _lastMessageCount = widget.chatManager.messages.length;
        setState(() {
          _isLoadingHistory = false;
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: false);
        });
      }
    } catch (e) {
      debugPrint('Error loading conversation history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _historyError = 'Failed to load conversation history: ${e.toString()}';
        });
      }
    }
  }

  void _onChatManagerChanged() {
    // Invalidate message cache when messages change (for status updates)
    _cachedProcessedMessages = null;

    // Check if we received a new message
    final currentMessageCount = widget.chatManager.messages.length;
    if (currentMessageCount > _lastMessageCount) {
      _lastMessageCount = currentMessageCount;

      // Auto-scroll only if user was at bottom
      if (_isUserAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: true);
        });
      }
    }

    // Trigger rebuild to ensure UI updates (e.g., message status changes)
    if (mounted) {
      setState(() {});
    }

    // Check if there's a new user message that needs AI response
    _checkForNewUserMessage();
  }

  void _onScroll() {
    // Cancel previous timer
    _scrollDebounceTimer?.cancel();

    // Create new timer (debounced scroll handling)
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      _handleScrollPosition();
    });
  }

  void _handleScrollPosition() {
    final positions = _itemPositionsListener.itemPositions.value;

    if (positions.isNotEmpty) {
      final lastVisible = positions.last.index;
      final totalItems = _processMessagesWithDates(widget.chatManager.messages).length;

      // User is at bottom if last item is visible
      final isAtBottom = lastVisible >= totalItems - 2;

      if (_isUserAtBottom != isAtBottom) {
        setState(() {
          _isUserAtBottom = isAtBottom;
          _showScrollToBottom = !isAtBottom;
        });
      }

      // Mark visible messages as read
      final maxIndex = positions.map((p) => p.index).reduce((a, b) => a > b ? a : b);
      if (maxIndex < widget.chatManager.messages.length) {
        widget.chatManager.updateLastReadPosition(maxIndex);
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (widget.chatManager.messages.isEmpty) return;

    final totalItems = _processMessagesWithDates(widget.chatManager.messages).length;
    if (totalItems == 0) return;

    // Check if scroll controller is attached before scrolling
    try {
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: totalItems - 1,
          duration: animate ? const Duration(milliseconds: 400) : const Duration(milliseconds: 1),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      // Scroll controller not ready yet, ignore
      debugPrint('Scroll controller not ready: $e');
    }
  }

  void _checkForNewUserMessage() {
    final messages = widget.chatManager.messages;
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      if (lastMessage.isUser &&
          lastMessage.text != _lastProcessedMessage &&
          lastMessage.text.isNotEmpty &&
          !lastMessage.text.startsWith("Hello! I'm your AI assistant")) {
        _lastProcessedMessage = lastMessage.text;

        // Skip triggering AI response for voice messages
        // They're already sent through the voice WebSocket to voice_gateway
        if (lastMessage.inputMode == 'voice') {
          debugPrint('⏭️ Skipping AI trigger for voice message (already sent via voice WebSocket)');

          // Update voice message status to sent
          if (lastMessage.status == MessageStatus.sending) {
            widget.chatManager.updateMessageStatus(
              lastMessage.id,
              MessageStatus.sent,
            );
          }
          return;
        }

        _triggerAIResponse(lastMessage);
      }
    }
  }

  void _triggerAIResponse(ChatMessage userMessage) async {
    if (userMessage.text.trim().isEmpty) return;

    _scrollToBottom();

    try {
      final response = await widget.chatService.getChatCompletion(
        widget.chatManager.messages,
      );

      if (!mounted) return;

      // Update message status to sent AFTER server confirms receipt
      if (userMessage.status == MessageStatus.sending) {
        widget.chatManager.updateMessageStatus(
          userMessage.id,
          MessageStatus.sent,
        );
      }

      if (response.isNotEmpty) {
        widget.chatManager.addMessage(response, false);
      }

      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;

      // Update message status to error
      widget.chatManager.updateMessageStatus(
        userMessage.id,
        MessageStatus.error,
        errorMessage: e.toString(),
      );

      final errorMessage = 'Sorry, I encountered an error: ${e.toString()}';
      widget.chatManager.addMessage(errorMessage, false);
      ChatToast.showError('Failed to get AI response');

      _scrollToBottom();

      debugPrint('Chat API Error: $e');
    }
  }

  List<_MessageWithDate> _processMessagesWithDates(List<ChatMessage> messages) {
    // Return cached result if message count hasn't changed
    if (_cachedProcessedMessages != null && _cachedMessageCount == messages.length) {
      return _cachedProcessedMessages!;
    }

    final List<_MessageWithDate> result = [];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (lastDate == null || !TimestampFormatter.isSameDay(lastDate, messageDate)) {
        result.add(_MessageWithDate(
          message: message,
          showDateSeparator: true,
          dateLabel: TimestampFormatter.formatDateSeparator(messageDate),
        ));
        lastDate = messageDate;
      } else {
        result.add(_MessageWithDate(message: message));
      }
    }

    // Cache the result
    _cachedProcessedMessages = result;
    _cachedMessageCount = messages.length;

    return result;
  }

  bool _shouldShowAvatar(int index, List<ChatMessage> messages) {
    if (index == 0) return true;

    final current = messages[index];
    final previous = messages[index - 1];

    // Different sender
    if (current.isUser != previous.isUser) return true;

    // Time gap > 5 minutes
    final timeDiff = current.timestamp.difference(previous.timestamp);
    if (timeDiff.inMinutes > 5) return true;

    return false;
  }

  bool _shouldShowTimestamp(int index, List<ChatMessage> messages) {
    // Always show timestamp for the last message
    if (index == messages.length - 1) return true;

    final current = messages[index];
    final next = messages[index + 1];

    // Different sender
    if (current.isUser != next.isUser) return true;

    // Time gap > 2 minutes
    final timeDiff = next.timestamp.difference(current.timestamp);
    if (timeDiff.inMinutes >= 2) return true;

    return false;
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
        ],
      ),
    );
  }

  Widget _buildAgentStatusIndicator() {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.statusNotifier,
      builder: (context, status, child) {
        if (status == null || status.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 0, top: 8, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 18,
                    color: Color(0xFF00BCD4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303030),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 44), // Balance for alignment
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    final unreadCount = widget.chatManager.unreadCount;

    return AnimatedOpacity(
      opacity: _showScrollToBottom ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: const Color(0xFF00BCD4),
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        child: InkWell(
          onTap: () => _scrollToBottom(animate: true),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusBanner() {
    String message;
    Color color;
    IconData icon;

    switch (_connectionState) {
      case WebSocketConnectionState.connecting:
        message = 'Connecting...';
        color = const Color(0xFFFFA726);
        icon = Icons.sync;
        break;
      case WebSocketConnectionState.reconnecting:
        message = 'Reconnecting...';
        color = const Color(0xFFFFA726);
        icon = Icons.sync;
        break;
      case WebSocketConnectionState.disconnected:
        message = 'Disconnected - Messages may be delayed';
        color = const Color(0xFFFF5252);
        icon = Icons.cloud_off;
        break;
      case WebSocketConnectionState.connected:
      default:
        return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 32,
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          // Network status banner
          _buildNetworkStatusBanner(),

          // Messages area
          Expanded(
            child: Stack(
              children: [
                if (_isLoadingHistory)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00BCD4)),
                        SizedBox(height: 16),
                        Text(
                          'Loading conversation history...',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                  )
                else if (_historyError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFFF5252),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _historyError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEDEDED),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadConversationHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // RepaintBoundary isolates message list from modal drag/resize
                  RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: widget.chatManager,
                      builder: (context, child) {
                        final messages = widget.chatManager.messages;
                        final processedMessages = _processMessagesWithDates(messages);

                        // Add extra item for agent status indicator
                        final hasAgentStatus = widget.statusNotifier.value != null &&
                                              widget.statusNotifier.value!.isNotEmpty;
                        final totalItems = processedMessages.length + (hasAgentStatus ? 1 : 0);

                        return ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            // Show agent status indicator as last item
                            if (hasAgentStatus && index == processedMessages.length) {
                              return _buildAgentStatusIndicator();
                            }

                            // Regular message
                            if (index >= processedMessages.length) {
                              return const SizedBox.shrink();
                            }
                            final item = processedMessages[index];
                            final messageIndex = messages.indexOf(item.message);

                            // Guard against indexOf returning -1
                            final showAvatar = messageIndex >= 0 ? _shouldShowAvatar(messageIndex, messages) : true;
                            final showTimestamp = messageIndex >= 0 ? _shouldShowTimestamp(messageIndex, messages) : true;

                            // RepaintBoundary on each message for maximum isolation
                            return RepaintBoundary(
                              child: Column(
                                children: [
                                  if (item.showDateSeparator && item.dateLabel != null)
                                    _buildDateSeparator(item.dateLabel!),
                                  _AnimatedMessageBubble(
                                    key: ValueKey(item.message.id),
                                    message: item.message,
                                    showAvatar: showAvatar,
                                    showTimestamp: showTimestamp,
                                    autoPlayAudioNotifier: widget.autoPlayAudioNotifier,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildScrollToBottomButton(),
                  ),

                // Three-dot menu (top-right)
                if (!_isLoadingHistory && _historyError == null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildOverflowMenu(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverflowMenu(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: const Icon(
          Icons.delete_outline,
          size: 20,
        ),
        color: const Color(0xFF757575),
        hoverColor: const Color(0xFFFF5252).withOpacity(0.1),
        splashColor: const Color(0xFFFF5252).withOpacity(0.2),
        tooltip: 'Delete Conversation',
        onPressed: () => _showDeleteConfirmationDialog(context),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Conversation?',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This will permanently delete all messages in this conversation and clear the agent\'s memory. This action cannot be undone.',
            style: TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5252),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _handleDeleteConversation();
    }
  }

  Future<void> _handleDeleteConversation() async {
    try {
      // Show loading state
      setState(() {
        _isLoadingHistory = true;
      });

      // Delete conversation and transcript
      await widget.chatService.deleteConversationAndTranscript();

      if (!mounted) return;

      // Clear local messages
      widget.chatManager.clearMessages();

      // Reset state
      setState(() {
        _isLoadingHistory = false;
        _historyError = null;
        _lastProcessedMessage = null;
        _lastMessageCount = 0;
      });

      // Show success toast
      ChatToast.showSuccess('Conversation deleted');

      // Reload conversation history (will be empty)
      await _loadConversationHistory();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
      });

      // Show error toast
      ChatToast.showError('Failed to delete conversation: $e');
    }
  }
}

class _MessageWithDate {
  final ChatMessage message;
  final bool showDateSeparator;
  final String? dateLabel;

  _MessageWithDate({
    required this.message,
    this.showDateSeparator = false,
    this.dateLabel,
  });
}

class _AnimatedMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final ValueNotifier<bool> autoPlayAudioNotifier;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.showAvatar,
    this.showTimestamp = true,
    required this.autoPlayAudioNotifier,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBubbleColor() {
    if (!widget.message.isUser) {
      return const Color(0xFF424242); // AI message
    }

    // User message - status-based colors
    switch (widget.message.status) {
      case MessageStatus.sending:
        return const Color(0xFF00BCD4).withOpacity(0.08);
      case MessageStatus.error:
        return const Color(0xFFFF5252).withOpacity(0.2);
      case MessageStatus.sent:
      case MessageStatus.received:
      default:
        return const Color(0xFF00BCD4).withOpacity(0.25);
    }
  }

  Color _getBorderColor() {
    if (widget.message.status == MessageStatus.error) {
      return const Color(0xFFFF5252).withOpacity(0.6);
    }
    return widget.message.isUser
        ? const Color(0xFF00BCD4).withOpacity(0.5)
        : Colors.white.withOpacity(0.05);
  }

  Widget _buildStatusIcon() {
    if (!widget.message.isUser) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (widget.message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF757575),
          ),
        );
      case MessageStatus.sent:
        icon = Icons.check;
        color = const Color(0xFF757575);
        break;
      case MessageStatus.error:
        icon = Icons.error_outline;
        color = const Color(0xFFFF5252);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, size: 12, color: color);
  }

  bool _containsMarkdown(String text) {
    // Check for common markdown patterns
    return text.contains('```') ||           // Code blocks
        text.contains('**') ||                // Bold
        text.contains('*') ||                 // Italic or bold
        text.contains('_') ||                 // Italic or bold
        text.contains('`') ||                 // Inline code
        text.contains('##') ||                // Headers
        text.contains('#') ||                 // Headers
        text.contains('- ') ||                // Unordered lists
        text.contains('* ') ||                // Unordered lists
        RegExp(r'^\d+\. ').hasMatch(text) ||  // Ordered lists
        text.contains('> ') ||                // Blockquotes
        (text.contains('[') && text.contains('](')); // Links
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          height: 36,
          onTap: _copyToClipboard,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.copy,
                size: 14,
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(width: 8),
              const Text(
                'Copy',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    if (_containsMarkdown(widget.message.text)) {
      return MarkdownBody(
        data: widget.message.text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            height: 1.4,
          ),
          code: TextStyle(
            color: const Color(0xFF00BCD4),
            backgroundColor: Colors.black.withOpacity(0.3),
            fontFamily: 'monospace',
          ),
          codeblockPadding: const EdgeInsets.all(12),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: const TextStyle(
            color: Color(0xFF757575),
            fontStyle: FontStyle.italic,
          ),
          h1: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h3: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          listBullet: const TextStyle(
            color: Color(0xFF00BCD4),
          ),
          a: const TextStyle(
            color: Color(0xFF00BCD4),
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final uri = Uri.parse(href);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        },
      );
    } else {
      return SelectableLinkify(
        onOpen: (link) async {
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        text: widget.message.text,
        style: const TextStyle(
          color: Color(0xFFEDEDED),
          fontSize: 14,
          height: 1.4,
        ),
        linkStyle: const TextStyle(
          color: Color(0xFF00BCD4),
          decoration: TextDecoration.underline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.message.isUser
            ? _buildUserMessage()
            : _buildAIMessage(),
      ),
    );
  }

  Widget _buildUserMessage() {
    final isVoiceMessage = widget.message.inputMode == 'voice';

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.showAvatar ? 16 : 8,
        left: 48,
        right: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Status icon and timestamp
          if (widget.showTimestamp)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Row(
                children: [
                  // Voice indicator
                  if (isVoiceMessage) ...[
                    const Icon(
                      Icons.mic,
                      size: 12,
                      color: Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 4),
                  ],
                  _buildStatusIcon(),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: TimestampFormatter.formatFullTimestamp(widget.message.timestamp),
                    child: Text(
                      TimestampFormatter.formatRelativeTime(widget.message.timestamp),
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) => _showContextMenu(context, details),
              child: _HoverableMessageBubble(
                isUser: true,
                showAvatar: widget.showAvatar,
                bubbleColor: _getBubbleColor(),
                borderColor: _getBorderColor(),
                child: _buildMessageContent(),
              ),
            ),
            ),
          if (widget.showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFFEDEDED),
                size: 16,
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAIMessage() {
    final hasAudio = widget.message.audioFilePath != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.showAvatar ? 16 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFEDEDED),
                size: 16,
              ),
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapDown: (details) => _showContextMenu(context, details),
                  child: _HoverableMessageBubble(
                    isUser: false,
                    showAvatar: widget.showAvatar,
                    bubbleColor: _getBubbleColor(),
                    borderColor: _getBorderColor(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Audio player (if available)
                        if (hasAudio) ...[
                          ValueListenableBuilder<bool>(
                            valueListenable: widget.autoPlayAudioNotifier,
                            builder: (context, shouldAutoPlay, child) {
                              // Check if we should auto-play this audio
                              final autoPlay = shouldAutoPlay && !widget.message.isUser;

                              // Reset the flag after reading it
                              if (autoPlay) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  widget.autoPlayAudioNotifier.value = false;
                                });
                              }

                              return AudioPlayerWidget(
                                audioFilePath: widget.message.audioFilePath!,
                                autoPlay: autoPlay,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        // Message content
                        _buildMessageContent(),
                      ],
                    ),
                  ),
                ),
                if (widget.showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Tooltip(
                      message: TimestampFormatter.formatFullTimestamp(widget.message.timestamp),
                      child: Text(
                        TimestampFormatter.formatRelativeTime(widget.message.timestamp),
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized hoverable message bubble that manages its own hover state
/// to prevent rebuilding the entire message widget on mouse movement
class _HoverableMessageBubble extends StatefulWidget {
  final bool isUser;
  final bool showAvatar;
  final Color bubbleColor;
  final Color borderColor;
  final Widget child;

  const _HoverableMessageBubble({
    required this.isUser,
    required this.showAvatar,
    required this.bubbleColor,
    required this.borderColor,
    required this.child,
  });

  @override
  State<_HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<_HoverableMessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.isUser ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: widget.bubbleColor,
          borderRadius: widget.isUser
              ? BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: Radius.circular(widget.showAvatar ? 4 : 16),
                )
              : BorderRadius.only(
                  topLeft: Radius.circular(widget.showAvatar ? 4 : 16),
                  topRight: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF00BCD4).withOpacity(0.7)
                : widget.borderColor,
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
