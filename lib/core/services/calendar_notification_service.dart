import 'dart:async';

/// Service for handling calendar-related notifications
class CalendarNotificationService {
  StreamController<Map<String, dynamic>>? _notificationController;

  CalendarNotificationService() {
    _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  }

  /// Stream of calendar notifications
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController?.stream ?? const Stream.empty();

  /// Process incoming notification
  void handleNotification(Map<String, dynamic> notification) {
    _notificationController?.add(notification);
  }

  /// Dispose resources
  void dispose() {
    _notificationController?.close();
    _notificationController = null;
  }
}
