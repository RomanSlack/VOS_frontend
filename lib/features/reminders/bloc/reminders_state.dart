import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/calendar_models.dart';

// ============================================================================
// Reminder States
// ============================================================================

abstract class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => [];
}

class RemindersInitial extends RemindersState {
  const RemindersInitial();
}

class RemindersLoading extends RemindersState {
  const RemindersLoading();
}

class RemindersLoaded extends RemindersState {
  final List<Reminder> reminders;
  final List<Reminder> triggeredReminders;

  const RemindersLoaded({
    required this.reminders,
    this.triggeredReminders = const [],
  });

  @override
  List<Object?> get props => [reminders, triggeredReminders];

  RemindersLoaded copyWith({
    List<Reminder>? reminders,
    List<Reminder>? triggeredReminders,
  }) {
    return RemindersLoaded(
      reminders: reminders ?? this.reminders,
      triggeredReminders: triggeredReminders ?? this.triggeredReminders,
    );
  }

  /// Group reminders by category
  Map<ReminderGroup, List<Reminder>> get groupedReminders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayReminders = <Reminder>[];
    final upcomingReminders = <Reminder>[];
    final recurringReminders = <Reminder>[];

    for (final reminder in reminders) {
      final triggerDate = DateTime(
        reminder.triggerTime.year,
        reminder.triggerTime.month,
        reminder.triggerTime.day,
      );

      if (reminder.isRecurring) {
        recurringReminders.add(reminder);
      } else if (triggerDate == today) {
        todayReminders.add(reminder);
      } else if (triggerDate.isAfter(today)) {
        upcomingReminders.add(reminder);
      }
    }

    return {
      ReminderGroup.today: todayReminders,
      ReminderGroup.upcoming: upcomingReminders,
      ReminderGroup.recurring: recurringReminders,
    };
  }
}

class RemindersError extends RemindersState {
  final String message;
  final String? details;

  const RemindersError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}

class RemindersOperationSuccess extends RemindersState {
  final String message;
  final List<Reminder> reminders;
  final List<Reminder> triggeredReminders;

  const RemindersOperationSuccess({
    required this.message,
    required this.reminders,
    this.triggeredReminders = const [],
  });

  @override
  List<Object?> get props => [message, reminders, triggeredReminders];
}

enum ReminderGroup {
  today,
  upcoming,
  recurring,
}
