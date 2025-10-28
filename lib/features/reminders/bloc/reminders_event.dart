import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/calendar_models.dart';

// ============================================================================
// Reminder Events
// ============================================================================

abstract class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminders extends RemindersEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const LoadReminders({
    this.startDate,
    this.endDate,
    this.limit,
  });

  @override
  List<Object?> get props => [startDate, endDate, limit];
}

class CreateReminder extends RemindersEvent {
  final CreateReminderRequest request;

  const CreateReminder(this.request);

  @override
  List<Object?> get props => [request];
}

class CreateTimer extends RemindersEvent {
  final String title;
  final Duration duration;
  final String? description;

  const CreateTimer({
    required this.title,
    required this.duration,
    this.description,
  });

  @override
  List<Object?> get props => [title, duration, description];
}

class CreateAlarm extends RemindersEvent {
  final String title;
  final DateTime time;
  final String? description;

  const CreateAlarm({
    required this.title,
    required this.time,
    this.description,
  });

  @override
  List<Object?> get props => [title, time, description];
}

class EditReminder extends RemindersEvent {
  final EditReminderRequest request;

  const EditReminder(this.request);

  @override
  List<Object?> get props => [request];
}

class DeleteReminder extends RemindersEvent {
  final String reminderId;

  const DeleteReminder(this.reminderId);

  @override
  List<Object?> get props => [reminderId];
}

class RefreshReminders extends RemindersEvent {
  const RefreshReminders();
}

/// Silent refresh that doesn't show loading state (for background updates)
class SilentRefreshReminders extends RemindersEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const SilentRefreshReminders({
    this.startDate,
    this.endDate,
    this.limit,
  });

  @override
  List<Object?> get props => [startDate, endDate, limit];
}

class ReminderTriggered extends RemindersEvent {
  final Reminder reminder;

  const ReminderTriggered(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class DismissTriggeredReminder extends RemindersEvent {
  final String reminderId;

  const DismissTriggeredReminder(this.reminderId);

  @override
  List<Object?> get props => [reminderId];
}
