import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/calendar_models.dart';

// ============================================================================
// Calendar States
// ============================================================================

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;
  final ConflictInfo? conflictInfo;

  const CalendarLoaded({
    required this.events,
    this.conflictInfo,
  });

  @override
  List<Object?> get props => [events, conflictInfo];

  CalendarLoaded copyWith({
    List<CalendarEvent>? events,
    ConflictInfo? conflictInfo,
  }) {
    return CalendarLoaded(
      events: events ?? this.events,
      conflictInfo: conflictInfo ?? this.conflictInfo,
    );
  }

  /// Get events for a specific date
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((event) {
      final eventDate = event.startTime.toLocal();
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  /// Get events for a date range
  List<CalendarEvent> getEventsInRange(DateTime start, DateTime end) {
    return events.where((event) {
      final eventStart = event.startTime.toLocal();
      return eventStart.isAfter(start) && eventStart.isBefore(end);
    }).toList();
  }
}

class CalendarError extends CalendarState {
  final String message;
  final String? details;

  const CalendarError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}

class CalendarOperationSuccess extends CalendarState {
  final String message;
  final List<CalendarEvent> events;
  final ConflictInfo? conflictInfo;

  const CalendarOperationSuccess({
    required this.message,
    required this.events,
    this.conflictInfo,
  });

  @override
  List<Object?> get props => [message, events, conflictInfo];
}
