import 'package:flutter/material.dart';
import 'package:vos_app/core/services/calendar_notification_service.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/calendar/bloc/calendar_event.dart';
import 'package:vos_app/features/reminders/bloc/reminders_bloc.dart';
import 'package:vos_app/features/reminders/bloc/reminders_event.dart';
import 'package:vos_app/presentation/widgets/notification_toast.dart';
import 'package:vos_app/core/utils/logger.dart';

/// Manager for coordinating calendar/reminder notifications with UI
class CalendarNotificationManager {
  final CalendarNotificationService _notificationService;
  final BuildContext context;
  CalendarBloc? _calendarBloc;
  RemindersBloc? _remindersBloc;

  CalendarNotificationManager({
    required this.context,
    CalendarNotificationService? notificationService,
  }) : _notificationService = notificationService ?? CalendarNotificationService() {
    _setupCallbacks();
  }

  /// Register BLoCs for event dispatching
  void registerBlocs({
    CalendarBloc? calendarBloc,
    RemindersBloc? remindersBloc,
  }) {
    _calendarBloc = calendarBloc;
    _remindersBloc = remindersBloc;
    logger.i('CalendarNotificationManager: BLoCs registered');
  }

  /// Setup callbacks for notification service
  void _setupCallbacks() {
    _notificationService.onReminderTriggered = _handleReminderTriggered;
    _notificationService.onEventCreated = _handleEventCreated;
    _notificationService.onEventUpdated = _handleEventUpdated;
    _notificationService.onEventDeleted = _handleEventDeleted;
  }

  /// Handle reminder triggered event
  void _handleReminderTriggered(Reminder reminder) {
    logger.i('CalendarNotificationManager: Handling reminder: ${reminder.title}');

    // Show toast notification
    NotificationToastManager.show(
      context,
      reminder,
      onDismiss: () {
        logger.d('CalendarNotificationManager: Reminder dismissed: ${reminder.id}');
        // Optionally dispatch to RemindersBloc
        _remindersBloc?.add(DismissTriggeredReminder(reminder.id));
      },
    );

    // Dispatch to RemindersBloc for state update
    _remindersBloc?.add(ReminderTriggered(reminder));
  }

  /// Handle event created notification
  void _handleEventCreated(CalendarEvent event) {
    logger.i('CalendarNotificationManager: Handling event created: ${event.title}');
    _calendarBloc?.add(CalendarEventAdded(event));
  }

  /// Handle event updated notification
  void _handleEventUpdated(CalendarEvent event) {
    logger.i('CalendarNotificationManager: Handling event updated: ${event.title}');
    _calendarBloc?.add(CalendarEventUpdated(event));
  }

  /// Handle event deleted notification
  void _handleEventDeleted(String eventId) {
    logger.i('CalendarNotificationManager: Handling event deleted: $eventId');
    _calendarBloc?.add(CalendarEventDeleted(eventId));
  }

  /// Connect to WebSocket
  Future<void> connect({String? sessionId, String? token}) async {
    logger.i('CalendarNotificationManager: Connecting to notification service');
    await _notificationService.connect(
      sessionId: sessionId ?? 'user_session_default',
      token: token,
    );
  }

  /// Disconnect from WebSocket
  void disconnect() {
    logger.i('CalendarNotificationManager: Disconnecting from notification service');
    _notificationService.disconnect();
  }

  /// Check if connected
  bool get isConnected => _notificationService.isConnected;

  /// Dispose of resources
  void dispose() {
    logger.i('CalendarNotificationManager: Disposing');
    _notificationService.dispose();
    _calendarBloc = null;
    _remindersBloc = null;
  }
}
