import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/di/injection.dart';

final _log = Logger('ConversationWebSocketService');

/// Message types received from the server
enum WebSocketMessageType {
  connected,
  newMessage,
  typingIndicator,
  agentStatus,
  pong,
  error,
  unknown,
}

/// Parsed WebSocket message
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'unknown';
    final type = _parseMessageType(typeStr);
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return WebSocketMessage(type: type, data: data);
  }

  static WebSocketMessageType _parseMessageType(String type) {
    switch (type) {
      case 'connected':
        return WebSocketMessageType.connected;
      case 'new_message':
        return WebSocketMessageType.newMessage;
      case 'typing_indicator':
        return WebSocketMessageType.typingIndicator;
      case 'agent_status':
        return WebSocketMessageType.agentStatus;
      case 'pong':
        return WebSocketMessageType.pong;
      case 'error':
        return WebSocketMessageType.error;
      default:
        return WebSocketMessageType.unknown;
    }
  }

  // Convenience getters for new_message type
  String? get messageId => data['message_id'] as String?;
  String? get conversationId => data['conversation_id'] as String?;
  String? get senderId => data['sender_id'] as String?;
  String? get senderType => data['sender_type'] as String?;
  String? get content => data['content'] as String?;
  String? get createdAt => data['created_at'] as String?;

  // Convenience getters for typing_indicator type
  String? get typingUserId => data['user_id'] as String?;
  bool get isTyping => data['is_typing'] as bool? ?? false;

  // Convenience getters for agent_status type
  String? get agentId => data['agent_id'] as String?;
  String? get status => data['status'] as String?;
  String? get actionDescription => data['action_description'] as String?;
}

/// Connection state
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket service for real-time conversation messaging
class ConversationWebSocketService {
  final AuthService _authService;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  String? _currentConversationId;
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Stream controllers for broadcasting events
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionStateController = StreamController<ConnectionState>.broadcast();

  /// Stream of incoming WebSocket messages
  Stream<WebSocketMessage> get messages => _messageController.stream;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;

  /// Current connection state
  ConnectionState get currentState => _connectionState;

  /// Currently connected conversation ID
  String? get currentConversationId => _currentConversationId;

  /// Whether connected to a conversation
  bool get isConnected => _connectionState == ConnectionState.connected;

  ConversationWebSocketService() : _authService = getIt<AuthService>();

  /// Connect to a conversation's WebSocket
  Future<bool> connect(String conversationId) async {
    // Disconnect from any existing connection
    if (_currentConversationId != null && _currentConversationId != conversationId) {
      await disconnect();
    }

    // Skip if already connected to this conversation
    if (_currentConversationId == conversationId && isConnected) {
      _log.info('Already connected to conversation $conversationId');
      return true;
    }

    _currentConversationId = conversationId;
    _updateState(ConnectionState.connecting);

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        _log.warning('No auth token available for WebSocket connection');
        _updateState(ConnectionState.error);
        return false;
      }

      final wsUrl = _buildWebSocketUrl(conversationId, token);
      _log.info('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start ping timer
      _startPingTimer();

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;

      return true;
    } catch (e) {
      _log.severe('Failed to connect WebSocket: $e');
      _updateState(ConnectionState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// Disconnect from the current conversation
  Future<void> disconnect() async {
    _log.info('Disconnecting from conversation ${_currentConversationId}');

    _pingTimer?.cancel();
    _pingTimer = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _currentConversationId = null;
    _reconnectAttempts = 0;
    _updateState(ConnectionState.disconnected);
  }

  /// Send a typing indicator
  void sendTypingIndicator(bool isTyping) {
    _sendMessage({
      'type': 'typing',
      'is_typing': isTyping,
    });
  }

  /// Send a read receipt
  void sendReadReceipt() {
    _sendMessage({
      'type': 'read',
    });
  }

  /// Send a ping to keep connection alive
  void sendPing() {
    _sendMessage({
      'type': 'ping',
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null || !isConnected) {
      _log.warning('Cannot send message: not connected');
      return;
    }

    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
      _log.fine('Sent: ${message['type']}');
    } catch (e) {
      _log.warning('Failed to send message: $e');
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      _log.info('Received: ${message.type}');

      // Handle connection confirmation
      if (message.type == WebSocketMessageType.connected) {
        _updateState(ConnectionState.connected);
      }

      // Broadcast message to listeners
      _messageController.add(message);
    } catch (e) {
      _log.warning('Failed to parse WebSocket message: $e');
    }
  }

  void _onError(dynamic error) {
    _log.severe('WebSocket error: $error');
    _updateState(ConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    _log.info('WebSocket connection closed');

    if (_connectionState != ConnectionState.disconnected) {
      _updateState(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _updateState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
      _log.info('Connection state: $state');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) {
        sendPing();
      }
    });
  }

  void _scheduleReconnect() {
    if (_currentConversationId == null) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log.warning('Max reconnect attempts reached');
      _updateState(ConnectionState.error);
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff
    final delay = Duration(
      milliseconds: (_initialReconnectDelay.inMilliseconds *
              (1 << _reconnectAttempts))
          .clamp(
        _initialReconnectDelay.inMilliseconds,
        _maxReconnectDelay.inMilliseconds,
      ),
    );

    _log.info('Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');
    _updateState(ConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      final conversationId = _currentConversationId;
      if (conversationId != null) {
        await connect(conversationId);
      }
    });
  }

  String _buildWebSocketUrl(String conversationId, String token) {
    // Convert HTTP URL to WebSocket URL
    final baseUrl = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    return '$baseUrl/ws/conversations/$conversationId?token=$token';
  }

  /// Dispose of the service
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
