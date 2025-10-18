import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/services/websocket_service.dart';
import 'package:vos_app/utils/timestamp_formatter.dart';
import 'package:vos_app/utils/chat_toast.dart';

class ChatApp extends StatefulWidget {
  final ChatManager chatManager;
  final ChatService chatService;
  final ValueNotifier<String?> statusNotifier;
  final ValueNotifier<bool> isActiveNotifier;

  const ChatApp({
    super.key,
    required this.chatManager,
    required this.chatService,
    required this.statusNotifier,
    required this.isActiveNotifier,
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
      final isThinking = statusPayload.processingState?.toLowerCase() == 'thinking';
      final isExecuting = statusPayload.processingState?.toLowerCase() == 'executing_tools';
      widget.isActiveNotifier.value = isThinking || isExecuting;
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
      final messages = await widget.chatService.loadConversationHistory();
      if (mounted) {
        widget.chatManager.loadMessages(messages);
        _lastMessageCount = messages.length;
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

    _itemScrollController.scrollTo(
      index: totalItems - 1,
      duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
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

      // Update message status to sent
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
      if (userMessage.status == MessageStatus.sending) {
        widget.chatManager.updateMessageStatus(
          userMessage.id,
          MessageStatus.error,
          errorMessage: e.toString(),
        );
      }

      final errorMessage = 'Sorry, I encountered an error: ${e.toString()}';
      widget.chatManager.addMessage(errorMessage, false);
      ChatToast.showError('Failed to get AI response');

      _scrollToBottom();

      debugPrint('Chat API Error: $e');
    }
  }

  List<_MessageWithDate> _processMessagesWithDates(List<ChatMessage> messages) {
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
                  ListenableBuilder(
                    listenable: widget.chatManager,
                    builder: (context, child) {
                      final messages = widget.chatManager.messages;
                      final processedMessages = _processMessagesWithDates(messages);

                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: processedMessages.length,
                        itemBuilder: (context, index) {
                          final item = processedMessages[index];
                          final messageIndex = messages.indexOf(item.message);

                          return Column(
                            children: [
                              if (item.showDateSeparator)
                                _buildDateSeparator(item.dateLabel!),
                              _AnimatedMessageBubble(
                                key: ValueKey(item.message.id),
                                message: item.message,
                                showAvatar: _shouldShowAvatar(messageIndex, messages),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildScrollToBottomButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.showAvatar,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

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
    return text.contains('```') ||
        text.contains('**') ||
        text.contains('##') ||
        (text.contains('[') && text.contains(']('));
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
      return Linkify(
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
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Row(
              children: [
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
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getBubbleColor(),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: Radius.circular(widget.showAvatar ? 4 : 16),
                  ),
                  border: Border.all(
                    color: _isHovered
                        ? const Color(0xFF00BCD4).withOpacity(0.7)
                        : _getBorderColor(),
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
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.showAvatar ? 4 : 16),
                        topRight: const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: _isHovered
                            ? const Color(0xFF00BCD4).withOpacity(0.3)
                            : _getBorderColor(),
                        width: 1,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
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
