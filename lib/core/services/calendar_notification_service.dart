import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/core/utils/logger.dart';

/// Service for handling real-time calendar and reminder notifications via WebSocket
class CalendarNotificationService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 5);

  // Callbacks for different event types
  Function(Reminder)? onReminderTriggered;
  Function(CalendarEvent)? onEventCreated;
  Function(CalendarEvent)? onEventUpdated;
  Function(String)? onEventDeleted;

  bool get isConnected => _isConnected;

  /// Connect to the WebSocket endpoint for calendar/reminder notifications
  Future<void> connect({
    String sessionId = 'user_session_default',
    String? token,
  }) async {
    if (_isConnected) {
      logger.w('CalendarNotificationService: Already connected');
      return;
    }

    try {
      // Build WebSocket URL for app-interaction notifications
      // Using the existing WebSocket endpoint with session
      final wsUrl = token != null
          ? AppConfig.getWebSocketUrl(sessionId, token)
          : '${AppConfig.wsBaseUrl}/api/v1/ws/notifications/app-interaction?agent_id=calendar_agent';

      logger.i('CalendarNotificationService: Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      logger.i('CalendarNotificationService: Connected successfully');
    } catch (e) {
      logger.e('CalendarNotificationService: Connection failed: $e');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      logger.d('CalendarNotificationService: Received message: $data');

      final action = data['action'] as String?;
      final appName = data['app_name'] as String?;
      final result = data['result'] as Map<String, dynamic>?;

      // Filter messages for calendar/reminders apps
      if (appName != 'calendar_app' && appName != 'reminders_app') {
        return;
      }

      switch (action) {
        case 'reminder_triggered':
          _handleReminderTriggered(result);
          break;
        case 'event_created':
          _handleEventCreated(result);
          break;
        case 'event_updated':
          _handleEventUpdated(result);
          break;
        case 'event_deleted':
          _handleEventDeleted(result);
          break;
        default:
          logger.d('CalendarNotificationService: Unhandled action: $action');
      }
    } catch (e) {
      logger.e('CalendarNotificationService: Error parsing message: $e');
    }
  }

  void _handleReminderTriggered(Map<String, dynamic>? result) {
    if (result == null || result['reminder'] == null) {
      logger.w('CalendarNotificationService: Invalid reminder_triggered payload');
      return;
    }

    try {
      final reminder = Reminder.fromJson(result['reminder'] as Map<String, dynamic>);
      logger.i('CalendarNotificationService: Reminder triggered: ${reminder.title}');
      onReminderTriggered?.call(reminder);
    } catch (e) {
      logger.e('CalendarNotificationService: Error parsing reminder: $e');
    }
  }

  void _handleEventCreated(Map<String, dynamic>? result) {
    if (result == null || result['event'] == null) {
      logger.w('CalendarNotificationService: Invalid event_created payload');
      return;
    }

    try {
      final event = CalendarEvent.fromJson(result['event'] as Map<String, dynamic>);
      logger.i('CalendarNotificationService: Event created: ${event.title}');
      onEventCreated?.call(event);
    } catch (e) {
      logger.e('CalendarNotificationService: Error parsing event: $e');
    }
  }

  void _handleEventUpdated(Map<String, dynamic>? result) {
    if (result == null || result['event'] == null) {
      logger.w('CalendarNotificationService: Invalid event_updated payload');
      return;
    }

    try {
      final event = CalendarEvent.fromJson(result['event'] as Map<String, dynamic>);
      logger.i('CalendarNotificationService: Event updated: ${event.title}');
      onEventUpdated?.call(event);
    } catch (e) {
      logger.e('CalendarNotificationService: Error parsing event: $e');
    }
  }

  void _handleEventDeleted(Map<String, dynamic>? result) {
    if (result == null || result['event_id'] == null) {
      logger.w('CalendarNotificationService: Invalid event_deleted payload');
      return;
    }

    try {
      final eventId = result['event_id'] as String;
      logger.i('CalendarNotificationService: Event deleted: $eventId');
      onEventDeleted?.call(eventId);
    } catch (e) {
      logger.e('CalendarNotificationService: Error parsing event_id: $e');
    }
  }

  void _handleError(dynamic error) {
    logger.e('CalendarNotificationService: WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    logger.w('CalendarNotificationService: WebSocket disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      logger.e('CalendarNotificationService: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectAttempts++;
      logger.i('CalendarNotificationService: Reconnect attempt $_reconnectAttempts/$maxReconnectAttempts');
      connect();
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    logger.i('CalendarNotificationService: Disconnecting');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
    onReminderTriggered = null;
    onEventCreated = null;
    onEventUpdated = null;
    onEventDeleted = null;
  }
}
