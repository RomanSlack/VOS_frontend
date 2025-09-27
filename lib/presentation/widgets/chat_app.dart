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
  bool _isThinking = false;
  String? _lastProcessedMessage;

  @override
  void initState() {
    super.initState();

    // Listen for changes and trigger AI responses for new user messages
    widget.chatManager.addListener(_onChatManagerChanged);

    // Check if there's a new user message that needs AI response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewUserMessage();
    });
  }

  void _onChatManagerChanged() {
    // Check if there's a new user message that needs AI response
    _checkForNewUserMessage();
  }

  void _checkForNewUserMessage() {
    final messages = widget.chatManager.messages;
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      if (lastMessage.isUser &&
          lastMessage.text != _lastProcessedMessage &&
          lastMessage.text.isNotEmpty) {
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

    setState(() {
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      // Get real AI response from the API
      final response = await widget.chatService.getChatCompletion(
        widget.chatManager.messages,
      );

      if (!mounted) return;

      widget.chatManager.addMessage(response, false);
      setState(() {
        _isThinking = false;
      });
      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;

      // Show error message in chat
      final errorMessage = 'Sorry, I encountered an error: ${e.toString()}';
      widget.chatManager.addMessage(errorMessage, false);

      setState(() {
        _isThinking = false;
      });
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
                ListenableBuilder(
                  listenable: widget.chatManager,
                  builder: (context, child) {
                    final messages = widget.chatManager.messages;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      itemCount: messages.length + (_isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isThinking && index == messages.length) {
                          return const _ThinkingIndicator();
                        }

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showAvatar ? 16 : 8,
        left: message.isUser ? 48 : 0,
        right: message.isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
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
          else if (!message.isUser)
            const SizedBox(width: 40),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                  ? const Color(0xFF00BCD4).withOpacity(0.15)
                  : const Color(0xFF424242),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(
                    !message.isUser && showAvatar ? 4 : 16
                  ),
                  bottomRight: Radius.circular(
                    message.isUser && showAvatar ? 4 : 16
                  ),
                ),
                border: Border.all(
                  color: message.isUser
                    ? const Color(0xFF00BCD4).withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(
                  color: const Color(0xFFEDEDED),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),

          if (message.isUser && showAvatar)
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
          else if (message.isUser)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_animation.value + delay) % 1.0;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: Color(0xFF00BCD4).withOpacity(
                          0.3 + (0.7 * (0.5 + 0.5 * (1 - (value * 2 - 1).abs()))),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

