import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/chat_service.dart';

class ChatApp extends StatefulWidget {
  final ChatManager chatManager;
  final ChatService chatService;

  const ChatApp({
    super.key,
    required this.chatManager,
    required this.chatService,
  });

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final ScrollController _scrollController = ScrollController();
  String? _lastProcessedMessage;
  int _lastMessageCount = 0;
  bool _isLoadingHistory = true;
  String? _historyError;
  String? _agentActionStatus;

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
      if (mounted) {
        setState(() {
          _agentActionStatus = actionPayload.actionDescription;
        });
      }
    });

    // Subscribe to message stream to clear status when message arrives
    widget.chatService.messageStream.listen((messagePayload) {
      if (mounted) {
        setState(() {
          _agentActionStatus = null; // Clear status when message arrives
        });
      }
    });

    // Initialize message count
    _lastMessageCount = widget.chatManager.messages.length;

    // Check if there's a new user message that needs AI response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewUserMessage();
    });
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
          _scrollToBottom();
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
    // Check if we received a new message (likely from WebSocket)
    final currentMessageCount = widget.chatManager.messages.length;
    if (currentMessageCount > _lastMessageCount) {
      _lastMessageCount = currentMessageCount;
    }

    // Check if there's a new user message that needs AI response
    _checkForNewUserMessage();
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
        _triggerAIResponse(lastMessage.text);
      }
    }
  }

  @override
  void dispose() {
    widget.chatManager.removeListener(_onChatManagerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _triggerAIResponse(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    _scrollToBottom();

    try {
      // Get real AI response from the API
      final response = await widget.chatService.getChatCompletion(
        widget.chatManager.messages,
      );

      if (!mounted) return;

      // Only add response if it's not empty (WebSocket responses come via stream)
      if (response.isNotEmpty) {
        widget.chatManager.addMessage(response, false);
      }

      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;

      // Show error message in chat
      final errorMessage = 'Sorry, I encountered an error: ${e.toString()}';
      widget.chatManager.addMessage(errorMessage, false);

      _scrollToBottom();

      // Log error for debugging
      debugPrint('Chat API Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF303030),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Assistant',
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.chatManager.messages.length} messages',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: Stack(
              children: [
                // Add status indicator
                if (_agentActionStatus != null)
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _agentActionStatus!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageBubble(
                            message: message,
                            showAvatar: index == 0 ||
                              messages[index - 1].isUser != message.isUser,
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      // User messages - keep existing design (not full width)
      return Padding(
        padding: EdgeInsets.only(
          bottom: showAvatar ? 16 : 8,
          left: 48,
          right: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Add timestamp before bubble
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 10,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: Radius.circular(showAvatar ? 4 : 16),
                  ),
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (showAvatar)
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
    } else {
      // AI messages - full width design
      return Padding(
        padding: EdgeInsets.only(
          bottom: showAvatar ? 16 : 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar)
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(showAvatar ? 4 : 16),
                        topRight: const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: SelectableText(
                      message.text,
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // Add timestamp below bubble
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      _formatTimestamp(message.timestamp),
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 10,
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
}
