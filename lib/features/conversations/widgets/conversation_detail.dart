import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/conversations/bloc/conversations_bloc.dart';
import 'package:vos_app/features/conversations/bloc/conversations_event.dart';
import 'package:vos_app/features/conversations/bloc/conversations_state.dart';

class ConversationDetail extends StatefulWidget {
  final ConversationDto conversation;
  final List<SocialMessageDto> messages;
  final bool isLoading;
  final Map<String, bool> typingUsers;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isWebSocketConnected;
  final Map<String, AgentStatusInfo> agentStatuses;

  const ConversationDetail({
    super.key,
    required this.conversation,
    required this.messages,
    this.isLoading = false,
    this.typingUsers = const {},
    this.showBackButton = false,
    this.onBack,
    this.isWebSocketConnected = false,
    this.agentStatuses = const {},
  });

  @override
  State<ConversationDetail> createState() => _ConversationDetailState();
}

class _ConversationDetailState extends State<ConversationDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // Near bottom - load more messages
      context.read<ConversationsBloc>().add(const LoadMoreMessages());
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ConversationsBloc>().add(SendMessage(content: content));
    _messageController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildMessageList(),
        ),
        if (widget.agentStatuses.isNotEmpty) _buildAgentStatusIndicator(),
        if (widget.typingUsers.isNotEmpty) _buildTypingIndicator(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFEDEDED)),
              onPressed: widget.onBack,
            ),
          _buildConversationAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getDisplayName(),
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildConnectionIndicator(),
                  ],
                ),
                if (_getSubtitle() != null)
                  Text(
                    _getSubtitle()!,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
            onPressed: _showOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationAvatar() {
    final isGroup = widget.conversation.conversationType == ConversationType.group;
    final isAgentChat = widget.conversation.conversationType == ConversationType.agentChat;

    if (isGroup || isAgentChat) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF4A4A4A),
        child: Icon(
          isAgentChat ? Icons.smart_toy : Icons.group,
          color: const Color(0xFFEDEDED),
          size: 18,
        ),
      );
    }

    final otherParticipant = widget.conversation.participants.firstWhere(
      (p) => p.participantType == ParticipantType.agent,
      orElse: () => widget.conversation.participants.first,
    );

    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAgentColor(otherParticipant.participantId),
      child: Text(
        _getAgentEmoji(otherParticipant.participantId),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildMessageList() {
    if (widget.isLoading && widget.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF757575)),
      );
    }

    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withOpacity(0.2),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation!',
              style: TextStyle(color: Color(0xFF616161), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Most recent at bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isLoading && index == widget.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF757575),
                ),
              ),
            ),
          );
        }

        final message = widget.messages[index];
        final isMe = message.senderType == ParticipantType.user;
        final showAvatar = !isMe && (index == 0 ||
            widget.messages[index - 1].senderId != message.senderId);

        return _buildMessageBubble(message, isMe, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(SocialMessageDto message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: _getAgentColor(message.senderId),
              child: Text(
                _getAgentEmoji(message.senderId),
                style: const TextStyle(fontSize: 12),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blue.shade700
                    : const Color(0xFF424242),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _formatAgentName(message.senderId),
                        style: TextStyle(
                          color: _getAgentColor(message.senderId),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Tooltip(
      message: widget.isWebSocketConnected ? 'Live connection' : 'Connecting...',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.isWebSocketConnected ? Colors.green : Colors.orange,
          shape: BoxShape.circle,
          boxShadow: widget.isWebSocketConnected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildAgentStatusIndicator() {
    final activeStatuses = widget.agentStatuses.values
        .where((s) => s.isActive)
        .toList();

    if (activeStatuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activeStatuses.map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: status.isThinking
                      ? const _ThinkingAnimation()
                      : const Icon(
                          Icons.build,
                          size: 14,
                          color: Colors.blue,
                        ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: _getAgentColor(status.agentId),
                  child: Text(
                    _getAgentEmoji(status.agentId),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.actionDescription ??
                        (status.isThinking ? 'Thinking...' : 'Working...'),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final typingList = widget.typingUsers.keys.toList();
    if (typingList.isEmpty) return const SizedBox.shrink();

    String text;
    if (typingList.length == 1) {
      text = '${_formatAgentName(typingList.first)} is typing...';
    } else if (typingList.length == 2) {
      text = '${_formatAgentName(typingList[0])} and ${_formatAgentName(typingList[1])} are typing...';
    } else {
      text = 'Several agents are typing...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: _TypingDots(),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF757575)),
              onPressed: () {
                // TODO: Attachment picker
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Color(0xFFEDEDED)),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF303030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF757575)),
            title: const Text(
              'Conversation Info',
              style: TextStyle(color: Color(0xFFEDEDED)),
            ),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show conversation info
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive, color: Color(0xFF757575)),
            title: const Text(
              'Archive',
              style: TextStyle(color: Color(0xFFEDEDED)),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<ConversationsBloc>().add(
                    ArchiveConversation(widget.conversation.conversationId),
                  );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (widget.conversation.name != null && widget.conversation.name!.isNotEmpty) {
      return widget.conversation.name!;
    }

    if (widget.conversation.conversationType == ConversationType.dm) {
      final other = widget.conversation.participants.firstWhere(
        (p) => p.participantType == ParticipantType.agent,
        orElse: () => widget.conversation.participants.first,
      );
      return _formatAgentName(other.participantId);
    }

    return 'Group Chat';
  }

  String? _getSubtitle() {
    if (widget.conversation.conversationType == ConversationType.group) {
      final count = widget.conversation.participants.length;
      return '$count participants';
    }
    return null;
  }

  String _formatAgentName(String agentId) {
    return agentId
        .replaceAll('_agent', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _getAgentEmoji(String agentId) {
    switch (agentId) {
      case 'weather_agent':
        return '';
      case 'calendar_agent':
        return '';
      case 'notes_agent':
        return '';
      case 'calculator_agent':
        return '';
      case 'search_agent':
        return '';
      case 'primary_agent':
        return '';
      default:
        return '';
    }
  }

  Color _getAgentColor(String agentId) {
    switch (agentId) {
      case 'weather_agent':
        return Colors.blue.shade700;
      case 'calendar_agent':
        return Colors.green.shade700;
      case 'notes_agent':
        return Colors.amber.shade700;
      case 'calculator_agent':
        return Colors.purple.shade700;
      case 'search_agent':
        return Colors.orange.shade700;
      case 'primary_agent':
        return Colors.teal.shade700;
      default:
        return const Color(0xFF4A4A4A);
    }
  }

  String _formatMessageTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return '';
    }
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2)
                .clamp(0.3, 1.0);

            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Color.fromRGBO(117, 117, 117, opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Animated thinking indicator (brain icon with pulse)
class _ThinkingAnimation extends StatefulWidget {
  const _ThinkingAnimation();

  @override
  State<_ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<_ThinkingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: const Icon(
            Icons.psychology,
            size: 14,
            color: Colors.purple,
          ),
        );
      },
    );
  }
}
