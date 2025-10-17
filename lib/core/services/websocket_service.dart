import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vos_app/core/models/chat_models.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebSocketService {
  WebSocketChannel? _channel;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // Stream controllers for broadcasting events
  final _messageController = StreamController<NewMessagePayload>.broadcast();
  final _statusController = StreamController<AgentStatusPayload>.broadcast();
  final _actionController = StreamController<AgentActionStatusPayload>.broadcast();
  final _appInteractionController = StreamController<AppInteractionPayload>.broadcast();
  final _stateController = StreamController<WebSocketConnectionState>.broadcast();

  // Getters for streams
  Stream<NewMessagePayload> get messageStream => _messageController.stream;
  Stream<AgentStatusPayload> get statusStream => _statusController.stream;
  Stream<AgentActionStatusPayload> get actionStream => _actionController.stream;
  Stream<AppInteractionPayload> get appInteractionStream => _appInteractionController.stream;
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;
  WebSocketConnectionState get state => _state;

  static const String _baseUrl = 'localhost:8000';

  String? _currentSessionId;
  String? _jwtToken;
  StreamSubscription? _messageSubscription;

  /// Connect to WebSocket for a specific conversation session
  /// [jwtToken] - JWT authentication token from login endpoint
  Future<void> connect(String sessionId, {String? jwtToken}) async {
    if (_state == WebSocketConnectionState.connected &&
        _currentSessionId == sessionId) {
      debugPrint('Already connected to session: $sessionId');
      return;
    }

    await disconnect();
    _currentSessionId = sessionId;
    _jwtToken = jwtToken;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_currentSessionId == null) return;

    try {
      _updateState(WebSocketConnectionState.connecting);

      // Build WebSocket URL with JWT token if available
      final tokenParam = _jwtToken != null ? 'token=$_jwtToken' : '';
      final uri = Uri.parse(
        'ws://$_baseUrl/api/v1/ws/conversations/$_currentSessionId/stream?$tokenParam'
      );

      debugPrint('🔌 Connecting to WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _updateState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0; // Reset reconnect counter on success

      debugPrint('✅ Connected to WebSocket');

    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _updateState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final jsonData = json.decode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(jsonData);

      debugPrint('📨 Received message type: ${message.type}');

      switch (message.type) {
        case 'connected':
          final connectedData = WebSocketConnectedData.fromJson(
            message.data as Map<String, dynamic>
          );
          debugPrint('Connected to session: ${connectedData.sessionId}');
          if (connectedData.pendingNotifications > 0) {
            debugPrint('📬 ${connectedData.pendingNotifications} pending notifications will be delivered');
          }
          break;

        case 'notification':
          _handleNotification(message.data as Map<String, dynamic>);
          break;

        case 'error':
          debugPrint('⚠️ Server error: ${message.data}');
          break;

        default:
          debugPrint('Unknown message type: ${message.type}');
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    try {
      final notification = WebSocketNotification.fromJson(data);

      debugPrint('🔔 Notification type: ${notification.notificationType}');

      switch (notification.notificationType) {
        case 'new_message':
          final payload = NewMessagePayload.fromJson(notification.payload);
          _messageController.add(payload);
          debugPrint('💬 New message from ${payload.agentId}');
          break;

        case 'agent_status':
          final payload = AgentStatusPayload.fromJson(notification.payload);
          _statusController.add(payload);
          debugPrint('📊 Agent status: ${payload.processingState ?? payload.status}');
          break;

        case 'agent_action_status':
          final payload = AgentActionStatusPayload.fromJson(notification.payload);
          _actionController.add(payload);
          debugPrint('💭 Agent action: ${payload.actionDescription}');
          break;

        case 'app_interaction':
          final payload = AppInteractionPayload.fromJson(notification.payload);
          _appInteractionController.add(payload);
          debugPrint('📱 App interaction: ${payload.appName} - ${payload.action}');
          break;

        default:
          debugPrint('Unknown notification type: ${notification.notificationType}');
      }
    } catch (e) {
      debugPrint('Error handling notification: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _updateState(WebSocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    debugPrint('🔌 WebSocket disconnected');
    if (_state != WebSocketConnectionState.disconnected) {
      _updateState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached. Please refresh.');
      return;
    }

    if (_reconnectTimer?.isActive ?? false) return;

    final delay = _getReconnectDelay();
    _reconnectAttempts++;

    debugPrint(
      '🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...'
    );

    _updateState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      _establishConnection();
    });
  }

  Duration _getReconnectDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, ... up to 30s
    // Ensure we don't use negative numbers for bit shifting
    final exponent = (_reconnectAttempts - 1).clamp(0, 10);
    final delay = (1000 * (1 << exponent)).clamp(1000, 30000);
    return Duration(milliseconds: delay);
  }

  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Send a message through the WebSocket (if needed for future features)
  void sendMessage(Map<String, dynamic> message) {
    if (_state == WebSocketConnectionState.connected && _channel != null) {
      _channel!.sink.add(json.encode(message));
      debugPrint('📤 Sent message: ${message['type']}');
    } else {
      debugPrint('⚠️ Cannot send message: WebSocket not connected');
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('Disconnecting WebSocket...');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _currentSessionId = null;
    _reconnectAttempts = 0;

    _updateState(WebSocketConnectionState.disconnected);
  }

  /// Dispose and clean up all resources
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _actionController.close();
    _appInteractionController.close();
    _stateController.close();
  }
}
