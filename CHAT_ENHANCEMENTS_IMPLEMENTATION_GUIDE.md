# Chat App Enhancements - Implementation Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Required Dependencies](#required-dependencies)
3. [Data Model Changes](#data-model-changes)
4. [Feature Implementation Details](#feature-implementation-details)
5. [Implementation Order](#implementation-order)
6. [Performance Considerations](#performance-considerations)

---

## Architecture Overview

### Current Structure
```
lib/
├── core/
│   ├── chat_manager.dart          # State management for chat
│   ├── services/
│   │   ├── chat_service.dart      # API & WebSocket communication
│   │   └── websocket_service.dart # WebSocket handling
│   └── models/
│       └── chat_models.dart       # Data models
└── presentation/
    └── widgets/
        ├── chat_app.dart          # Main chat UI
        ├── input_bar.dart         # Text input at bottom (separate)
        └── vos_modal.dart         # Modal wrapper
```

### Key Components
- **ChatManager**: Manages message state, notifies listeners on changes
- **ChatService**: Handles HTTP API calls and WebSocket initialization
- **WebSocketService**: Real-time message/status streaming
- **ChatApp**: Main chat UI with ListView of messages
- **InputBar**: Separate widget at bottom of home page

---

## Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...

  # For Markdown rendering
  flutter_markdown: ^0.7.4+1
  markdown: ^7.2.2

  # For code syntax highlighting
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0

  # For URL detection and launching (already have url_launcher)
  linkify: ^5.0.2
  flutter_linkify: ^6.0.0

  # For relative time formatting (already have intl)
  timeago: ^3.7.0

  # For toast notifications
  fluttertoast: ^8.2.8
  # OR
  toastification: ^2.3.0

  # For virtualized lists (performance)
  flutter_sticky_header: ^0.6.5
  scrollable_positioned_list: ^0.3.8
```

**Note**: You already have `intl`, `url_launcher`, and other utilities, so we'll leverage those.

---

## Data Model Changes

### 1. Enhanced ChatMessage Model

**Location**: `lib/core/chat_manager.dart`

#### Current Model
```dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
}
```

#### Enhanced Model
```dart
enum MessageStatus {
  sending,     // Optimistic update - message being sent
  sent,        // Successfully sent to server
  error,       // Failed to send
  received,    // Received from server (for AI messages)
}

class ChatMessage {
  final String id;              // Unique ID for tracking
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;   // NEW: Message delivery status
  final String? errorMessage;   // NEW: Error details if status == error

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.received,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4();

  // Add copyWith for status updates
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

### 2. Enhanced ChatManager

**Add these methods to ChatManager**:

```dart
class ChatManager extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isConnected = true; // WebSocket connection status

  // ... existing code ...

  // Add optimistic message (user message before server confirmation)
  String addOptimisticMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(message);
    notifyListeners();
    return message.id;
  }

  // Update message status after server response
  void updateMessageStatus(String messageId, MessageStatus status, {String? errorMessage}) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        status: status,
        errorMessage: errorMessage,
      );
      notifyListeners();
    }
  }

  // Update connection status
  void setConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    }
  }

  bool get isConnected => _isConnected;
}
```

---

## Feature Implementation Details

### 1. Markdown Support & Code Syntax Highlighting

**Files to modify**: `lib/presentation/widgets/chat_app.dart`

#### Implementation

```dart
// Add imports
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:markdown/markdown.dart' as md;

// Replace SelectableText in _MessageBubble with:
class _MessageBubble extends StatelessWidget {
  // ... existing code ...

  Widget _buildMessageContent() {
    // For code blocks and markdown
    return MarkdownBody(
      data: message.text,
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
        // ... more styles
      ),
      syntaxHighlighter: CustomSyntaxHighlighter(),
    );
  }
}

// Custom syntax highlighter
class CustomSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    // Use flutter_highlight for code highlighting
    return TextSpan(
      children: highlight.parse(source, language: 'dart').nodes!.map((node) {
        return TextSpan(
          text: node.value,
          style: monokaiSublimeTheme[node.className],
        );
      }).toList(),
    );
  }
}
```

**Key Points**:
- Use `flutter_markdown` for rendering markdown
- Use `flutter_highlight` for code syntax highlighting
- Custom style sheet to match dark theme
- Language auto-detection for code blocks

---

### 2. Link Detection

**Files to modify**: `lib/presentation/widgets/chat_app.dart`

#### Implementation

```dart
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

// Alternative to MarkdownBody when no markdown detected:
Widget _buildMessageContent() {
  // Check if message contains markdown
  if (_containsMarkdown(message.text)) {
    return _buildMarkdownContent();
  } else {
    // Use Linkify for simple text with URLs
    return Linkify(
      onOpen: (link) async {
        if (await canLaunchUrl(Uri.parse(link.url))) {
          await launchUrl(Uri.parse(link.url));
        }
      },
      text: message.text,
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

bool _containsMarkdown(String text) {
  // Simple check for common markdown patterns
  return text.contains('```') ||
         text.contains('**') ||
         text.contains('##') ||
         text.contains('[') && text.contains('](');
}
```

---

### 3. Message Grouping

**Grouping Logic**: Show avatar/timestamp only when sender changes or time gap > 5 minutes

```dart
// In ListView.builder itemBuilder:
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
```

---

### 4. Date Separators

**Implementation**:

```dart
// Create a helper to build date separators
class MessageWithDate {
  final ChatMessage message;
  final bool showDateSeparator;
  final String? dateLabel;

  MessageWithDate({
    required this.message,
    this.showDateSeparator = false,
    this.dateLabel,
  });
}

// Process messages to add date separators
List<MessageWithDate> _processMessagesWithDates(List<ChatMessage> messages) {
  final List<MessageWithDate> result = [];
  DateTime? lastDate;

  for (var i = 0; i < messages.length; i++) {
    final message = messages[i];
    final messageDate = DateTime(
      message.timestamp.year,
      message.timestamp.month,
      message.timestamp.day,
    );

    if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
      result.add(MessageWithDate(
        message: message,
        showDateSeparator: true,
        dateLabel: _formatDateSeparator(messageDate),
      ));
      lastDate = messageDate;
    } else {
      result.add(MessageWithDate(message: message));
    }
  }

  return result;
}

bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

String _formatDateSeparator(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (_isSameDay(date, today)) return 'Today';
  if (_isSameDay(date, yesterday)) return 'Yesterday';

  // Format as "Jan 15, 2025"
  return DateFormat('MMM d, y').format(date);
}

// Widget for date separator
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
```

---

### 5. Message Animations & Auto-Scroll

**Implementation**:

```dart
class _ChatAppState extends State<ChatApp> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isUserAtBottom = true;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();

    // Listen to scroll position
    _scrollController.addListener(_onScroll);

    // Listen for new messages
    widget.chatManager.addListener(_onNewMessage);
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >=
                        _scrollController.position.maxScrollExtent - 100;

    if (_isUserAtBottom != isAtBottom) {
      setState(() {
        _isUserAtBottom = isAtBottom;
        _showScrollToBottom = !isAtBottom;
      });
    }
  }

  void _onNewMessage() {
    // Auto-scroll only if user was at bottom
    if (_isUserAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: true);
      });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  // ... rest of code
}

// Animate new messages
class _AnimatedMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAvatar;

  const _AnimatedMessageBubble({
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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _MessageBubble(
          message: widget.message,
          showAvatar: widget.showAvatar,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### 6. Scroll Position Indicator

**Implementation**:

```dart
// Add to build method in ChatApp
Stack(
  children: [
    ListView.builder(/* ... */),

    // Scroll to bottom button
    if (_showScrollToBottom)
      Positioned(
        bottom: 16,
        right: 16,
        child: _buildScrollToBottomButton(),
      ),
  ],
)

Widget _buildScrollToBottomButton() {
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
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
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
```

---

### 7. Better Error Styling & Message Status

**Implementation**:

```dart
// In _MessageBubble, determine bubble color based on status
Color _getBubbleColor() {
  if (!message.isUser) {
    return const Color(0xFF424242); // AI message
  }

  // User message - status-based colors
  switch (message.status) {
    case MessageStatus.sending:
      return const Color(0xFF00BCD4).withOpacity(0.05); // Very subtle
    case MessageStatus.error:
      return const Color(0xFFFF5252).withOpacity(0.15); // Red tint
    case MessageStatus.sent:
    case MessageStatus.received:
    default:
      return const Color(0xFF00BCD4).withOpacity(0.15); // Normal
  }
}

// Smooth color transition
class _MessageBubble extends StatefulWidget {
  // ... as AnimatedMessageBubble above
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        borderRadius: /* ... */,
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      // ... rest
    );
  }

  Color _getBorderColor() {
    if (widget.message.status == MessageStatus.error) {
      return const Color(0xFFFF5252).withOpacity(0.5);
    }
    return widget.message.isUser
        ? const Color(0xFF00BCD4).withOpacity(0.3)
        : Colors.white.withOpacity(0.05);
  }
}

// Add status icon
Widget _buildStatusIcon() {
  if (!message.isUser) return const SizedBox.shrink();

  IconData icon;
  Color color;

  switch (message.status) {
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
```

---

### 8. Network Status Indicator

**Implementation**:

```dart
// In ChatApp, listen to WebSocket connection state
class _ChatAppState extends State<ChatApp> {
  WebSocketConnectionState _connectionState = WebSocketConnectionState.connected;

  @override
  void initState() {
    super.initState();

    // Listen to connection state
    widget.chatService.stateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
      widget.chatManager.setConnectionStatus(
        state == WebSocketConnectionState.connected
      );
    });
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          // Network status banner
          if (_connectionState != WebSocketConnectionState.connected)
            _buildNetworkStatusBanner(),

          // Messages area
          Expanded(/* ... */),
        ],
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
      default:
        message = 'Disconnected - Messages may be delayed';
        color = const Color(0xFFFF5252);
        icon = Icons.cloud_off;
        break;
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
}
```

---

### 9. Toast Notifications

**Implementation**:

```dart
import 'package:fluttertoast/fluttertoast.dart';

// Helper class for consistent toasts
class ChatToast {
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFFF5252),
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF00BCD4),
      textColor: Colors.white,
      fontSize: 14,
    );
  }
}

// Usage in error handling
try {
  final response = await widget.chatService.getChatCompletion(messages);
  // ...
} catch (e) {
  ChatToast.showError('Failed to send message: ${e.toString()}');

  // Update message status to error
  widget.chatManager.updateMessageStatus(
    messageId,
    MessageStatus.error,
    errorMessage: e.toString(),
  );
}
```

---

### 10. Optimistic Updates

**Implementation in InputBar**:

```dart
// In InputBar._handleSubmit
void _handleSubmit(String text) async {
  if (text.trim().isEmpty) return;

  // Add optimistic message immediately
  final messageId = widget.modalManager.chatManager.addOptimisticMessage(text);

  // Clear input
  _controller.clear();

  // Send to server
  try {
    final response = await widget.modalManager.chatManager.sendMessage(text);

    // Update to sent status
    widget.modalManager.chatManager.updateMessageStatus(
      messageId,
      MessageStatus.sent,
    );
  } catch (e) {
    // Update to error status
    widget.modalManager.chatManager.updateMessageStatus(
      messageId,
      MessageStatus.error,
      errorMessage: e.toString(),
    );

    ChatToast.showError('Failed to send message');
  }
}
```

**Update ChatService.getChatCompletion**:

```dart
Future<String> getChatCompletion(List<ChatMessage> messages, String messageId) async {
  try {
    // ... existing send logic ...

    // Don't add message to ChatManager here - already added optimistically
    // Just return response

  } catch (e) {
    // Let caller handle error and update status
    rethrow;
  }
}
```

---

### 11. Hover States

**Implementation**:

```dart
class _MessageBubble extends StatefulWidget {
  // ... existing code
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _getBubbleColor(),
          borderRadius: /* ... */,
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF00BCD4).withOpacity(0.5)
                : _getBorderColor(),
            width: 1,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        // ... rest
      ),
    );
  }
}
```

---

### 12. Relative Timestamps

**Implementation**:

```dart
import 'package:timeago/timeago.dart' as timeago;

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  // Less than 1 minute: "Just now"
  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  // Less than 1 hour: "5m ago"
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }

  // Today: "2h ago" or show time if > 6h
  if (difference.inDays == 0) {
    if (difference.inHours < 6) {
      return '${difference.inHours}h ago';
    }
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Yesterday: "Yesterday at 14:30"
  if (difference.inDays == 1) {
    return 'Yesterday at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Within a week: "3 days ago"
  if (difference.inDays < 7) {
    return timeago.format(timestamp, locale: 'en_short');
  }

  // Older: "Jan 15, 14:30"
  return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
}

// For tooltip on hover - full timestamp
String _formatFullTimestamp(DateTime timestamp) {
  return DateFormat('MMM d, y \'at\' h:mm a').format(timestamp);
}

// In message bubble
Widget _buildTimestamp() {
  return Tooltip(
    message: _formatFullTimestamp(message.timestamp),
    child: Text(
      _formatTimestamp(message.timestamp),
      style: const TextStyle(
        color: Color(0xFF757575),
        fontSize: 10,
      ),
    ),
  );
}
```

---

### 13. Message Virtualization

**Implementation using scrollable_positioned_list**:

```dart
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class _ChatAppState extends State<ChatApp> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    // Listen to scroll position
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;

    if (positions.isNotEmpty) {
      final lastVisible = positions.last.index;
      final totalItems = widget.chatManager.messages.length;

      // User is at bottom if last item is visible
      final isAtBottom = lastVisible >= totalItems - 2;

      if (_isUserAtBottom != isAtBottom) {
        setState(() {
          _isUserAtBottom = isAtBottom;
          _showScrollToBottom = !isAtBottom;
        });
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (widget.chatManager.messages.isEmpty) return;

    _itemScrollController.scrollTo(
      index: widget.chatManager.messages.length - 1,
      duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: processedMessages.length,
      itemBuilder: (context, index) {
        final item = processedMessages[index];

        return Column(
          children: [
            if (item.showDateSeparator)
              _buildDateSeparator(item.dateLabel!),
            _AnimatedMessageBubble(
              key: ValueKey(item.message.id),
              message: item.message,
              showAvatar: _shouldShowAvatar(index, messages),
            ),
          ],
        );
      },
    );
  }
}
```

**Performance Note**: Virtualization automatically handles rendering only visible items, crucial for long conversations (1000+ messages).

---

### 14. Debounced Scroll Events

**Implementation**:

```dart
import 'dart:async';

class _ChatAppState extends State<ChatApp> {
  Timer? _scrollDebounceTimer;

  void _onScroll() {
    // Cancel previous timer
    _scrollDebounceTimer?.cancel();

    // Create new timer
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Actual scroll handling
      _handleScrollPosition();
    });
  }

  void _handleScrollPosition() {
    final positions = _itemPositionsListener.itemPositions.value;
    // ... scroll logic
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }
}
```

---

### 15. Scroll to Unread

**Implementation**:

```dart
class ChatManager extends ChangeNotifier {
  int _lastReadIndex = -1;

  int get unreadCount {
    if (_lastReadIndex < 0) return 0;
    return _messages.length - _lastReadIndex - 1;
  }

  void markAsRead() {
    _lastReadIndex = _messages.length - 1;
    notifyListeners();
  }

  // Called when user opens chat or scrolls to bottom
  void updateLastReadPosition(int index) {
    if (index > _lastReadIndex) {
      _lastReadIndex = index;
      notifyListeners();
    }
  }
}

// In ChatApp
void _onScroll() {
  // ... existing logic

  // Mark visible messages as read
  final positions = _itemPositionsListener.itemPositions.value;
  if (positions.isNotEmpty) {
    final maxIndex = positions.map((p) => p.index).reduce((a, b) => a > b ? a : b);
    widget.chatManager.updateLastReadPosition(maxIndex);
  }
}

// Show unread indicator
Widget _buildScrollToBottomButton() {
  final unreadCount = widget.chatManager.unreadCount;

  return AnimatedOpacity(
    // ... existing code
    child: /* badge showing unreadCount */,
  );
}
```

---

### 16. Contrast Improvements

**Current Issue**: User message bubble uses `Color(0xFF00BCD4).withOpacity(0.15)` which may be too subtle.

**Improved Colors**:

```dart
// User message - improved contrast
const userBubbleColor = Color(0xFF00BCD4).withOpacity(0.25); // Increased from 0.15
const userBubbleBorder = Color(0xFF00BCD4).withOpacity(0.5); // Increased from 0.3

// AI message - keep current
const aiBubbleColor = Color(0xFF424242);
const aiBubbleBorder = Colors.white.withOpacity(0.05);

// Error state - highly visible
const errorBubbleColor = Color(0xFFFF5252).withOpacity(0.2);
const errorBubbleBorder = Color(0xFFFF5252).withOpacity(0.6);

// Sending state - very subtle
const sendingBubbleColor = Color(0xFF00BCD4).withOpacity(0.08);
```

---

## Implementation Order

Recommended order to implement features:

### Phase 1: Foundation (Start Here)
1. **Data Model Changes** - Update ChatMessage and ChatManager
2. **Message Status Icons** - Basic visual feedback
3. **Optimistic Updates** - Immediate user feedback
4. **Better Error Styling** - Improved error visibility

### Phase 2: Content Rendering
5. **Markdown Support** - Add flutter_markdown
6. **Code Syntax Highlighting** - Integrate with markdown
7. **Link Detection** - URL handling
8. **Contrast Improvements** - Color adjustments

### Phase 3: UX Enhancements
9. **Message Grouping** - Smart avatar/timestamp display
10. **Date Separators** - Conversation organization
11. **Relative Timestamps** - User-friendly time display
12. **Hover States** - Interactive feedback

### Phase 4: Advanced Features
13. **Message Animations** - Smooth entry animations
14. **Auto-Scroll Logic** - Smart scrolling behavior
15. **Scroll Position Indicator** - "Scroll to bottom" button
16. **Scroll to Unread** - Unread message tracking

### Phase 5: Performance & Network
17. **Network Status** - Connection indicator
18. **Toast Notifications** - Non-intrusive alerts
19. **Debounced Scroll Events** - Performance optimization
20. **Message Virtualization** - Large conversation support

---

## Performance Considerations

### 1. Virtualization
- **Critical for 500+ messages**
- Use `scrollable_positioned_list` instead of `ListView`
- Only renders visible items + buffer

### 2. Debouncing
- Scroll events: 100ms debounce
- Search/filter: 300ms debounce

### 3. Animation Performance
- Use `RepaintBoundary` for message bubbles
- Limit simultaneous animations to 10 items
- Use `AnimatedBuilder` instead of `setState` where possible

### 4. State Management
- Keep markdown parsing memoized
- Cache formatted timestamps
- Lazy load conversation history in chunks

### 5. Memory Management
```dart
// Limit in-memory messages
class ChatManager {
  static const int maxMessagesInMemory = 1000;

  void _trimMessages() {
    if (_messages.length > maxMessagesInMemory) {
      _messages.removeRange(0, _messages.length - maxMessagesInMemory);
    }
  }
}
```

---

## Testing Checklist

- [ ] Send message - optimistic update appears immediately
- [ ] Message status transitions: sending → sent
- [ ] Error handling - status changes to error, toast appears
- [ ] Network disconnect - banner appears
- [ ] Network reconnect - banner disappears
- [ ] Scroll to bottom when at bottom (auto-scroll)
- [ ] Don't scroll when user is reading history
- [ ] "Scroll to bottom" button appears when scrolled up
- [ ] Unread count shows on scroll button
- [ ] Date separators appear correctly
- [ ] Message grouping - avatars appear/disappear correctly
- [ ] Relative timestamps update (test with old messages)
- [ ] Hover states work on desktop
- [ ] Links are clickable
- [ ] Markdown renders correctly
- [ ] Code blocks have syntax highlighting
- [ ] Long conversations (1000+ messages) perform well
- [ ] Scroll position maintained during message receive
- [ ] Animations don't lag

---

## Common Pitfalls & Solutions

### Issue: Messages jump when new one arrives
**Solution**: Use keyed widgets (`ValueKey(message.id)`) in ListView

### Issue: Auto-scroll too aggressive
**Solution**: Only auto-scroll if `_isUserAtBottom == true`

### Issue: Animations lag with many messages
**Solution**: Implement virtualization, limit animation to viewport

### Issue: Status doesn't update after send
**Solution**: Ensure `notifyListeners()` called after status change

### Issue: Timestamps not updating
**Solution**: Use `Timer.periodic` to rebuild relative timestamps every minute

### Issue: WebSocket reconnect not detected
**Solution**: Listen to `chatService.stateStream` properly

---

## Additional Enhancements (Optional)

### 1. Message Actions Menu
- Copy text
- Retry send (for errors)
- Delete message

### 2. Rich Media Support
- Image rendering
- File attachments
- Voice messages

### 3. Search & Filter
- Search conversation history
- Filter by date/sender

### 4. Persistence
- Cache messages locally (Hive)
- Load history on demand (pagination)

---

## File Structure After Implementation

```
lib/
├── core/
│   ├── chat_manager.dart (Enhanced with status)
│   └── services/
│       └── chat_service.dart (Optimistic updates)
├── presentation/
│   └── widgets/
│       ├── chat_app.dart (Main implementation)
│       ├── message_bubble.dart (NEW - extracted component)
│       ├── date_separator.dart (NEW)
│       ├── scroll_to_bottom_button.dart (NEW)
│       └── network_status_banner.dart (NEW)
└── utils/
    ├── chat_toast.dart (NEW - toast utilities)
    ├── timestamp_formatter.dart (NEW)
    └── markdown_utils.dart (NEW)
```

---

## Summary

This implementation guide covers all requested features with production-ready code patterns. Key highlights:

1. **Immediate feedback**: Optimistic updates + status indicators
2. **Rich content**: Markdown, code highlighting, links
3. **Smart UX**: Auto-scroll, grouping, relative times
4. **Performance**: Virtualization, debouncing, efficient rendering
5. **Error handling**: Status tracking, toasts, network indicators

Follow the implementation order for a smooth rollout. Start with Phase 1 (foundation), test thoroughly, then proceed to subsequent phases.
