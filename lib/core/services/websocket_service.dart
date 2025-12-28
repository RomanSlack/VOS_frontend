import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/config/app_config.dart';

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
  final _browserScreenshotController = StreamController<BrowserScreenshotPayload>.broadcast();
  final _stateController = StreamController<WebSocketConnectionState>.broadcast();

  // Getters for streams
  Stream<NewMessagePayload> get messageStream => _messageController.stream;
  Stream<AgentStatusPayload> get statusStream => _statusController.stream;
  Stream<AgentActionStatusPayload> get actionStream => _actionController.stream;
  Stream<AppInteractionPayload> get appInteractionStream => _appInteractionController.stream;
  Stream<BrowserScreenshotPayload> get browserScreenshotStream => _browserScreenshotController.stream;
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;
  WebSocketConnectionState get state => _state;

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

      // Build WebSocket URL using config (supports both ws:// and wss://)
      final wsUrl = AppConfig.getWebSocketUrl(
        _currentSessionId!,
        _jwtToken ?? '',
      );
      final uri = Uri.parse(wsUrl);

      debugPrint('🔌 Connecting to WebSocket: $uri');

      // For Android emulator, add Host header for localhost
      if (!kIsWeb && AppConfig.apiBaseUrl.contains('10.0.2.2')) {
        debugPrint('🔧 Setting Host header to localhost:8000 for Android');
        _channel = IOWebSocketChannel.connect(
          uri,
          headers: {'Host': 'localhost:8000'},
        );
      } else {
        _channel = WebSocketChannel.connect(uri);
      }

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

        case 'browser_screenshot':
          final payload = BrowserScreenshotPayload.fromJson(notification.payload);
          _browserScreenshotController.add(payload);
          debugPrint('Browser screenshot received: ${payload.currentUrl}');
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
    _browserScreenshotController.close();
    _stateController.close();
  }
}
