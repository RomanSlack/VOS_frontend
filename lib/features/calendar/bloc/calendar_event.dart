import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/calendar_models.dart';

// ============================================================================
// Calendar BLoC Events
// ============================================================================

abstract class CalendarBlocEvent extends Equatable {
  const CalendarBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadCalendarEvents extends CalendarBlocEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const LoadCalendarEvents({
    this.startDate,
    this.endDate,
    this.limit,
  });

  @override
  List<Object?> get props => [startDate, endDate, limit];
}

class CreateCalendarEvent extends CalendarBlocEvent {
  final CreateEventRequest request;

  const CreateCalendarEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateCalendarEvent extends CalendarBlocEvent {
  final UpdateEventRequest request;

  const UpdateCalendarEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class DeleteCalendarEvent extends CalendarBlocEvent {
  final DeleteEventRequest request;

  const DeleteCalendarEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class RefreshCalendarEvents extends CalendarBlocEvent {
  const RefreshCalendarEvents();
}

class CalendarEventAdded extends CalendarBlocEvent {
  final CalendarEvent event;

  const CalendarEventAdded(this.event);

  @override
  List<Object?> get props => [event];
}

class CalendarEventUpdated extends CalendarBlocEvent {
  final CalendarEvent event;

  const CalendarEventUpdated(this.event);

  @override
  List<Object?> get props => [event];
}

class CalendarEventDeleted extends CalendarBlocEvent {
  final String eventId;

  const CalendarEventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
