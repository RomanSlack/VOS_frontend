import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/api/calendar_api.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/calendar/bloc/calendar_event.dart';
import 'package:vos_app/features/calendar/bloc/calendar_state.dart';

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarState> {
  final CalendarToolHelper calendarApi;

  CalendarBloc(this.calendarApi) : super(const CalendarInitial()) {
    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<CreateCalendarEvent>(_onCreateCalendarEvent);
    on<UpdateCalendarEvent>(_onUpdateCalendarEvent);
    on<DeleteCalendarEvent>(_onDeleteCalendarEvent);
    on<RefreshCalendarEvents>(_onRefreshCalendarEvents);
    on<CalendarEventAdded>(_onCalendarEventAdded);
    on<CalendarEventUpdated>(_onCalendarEventUpdated);
    on<CalendarEventDeleted>(_onCalendarEventDeleted);
  }

  Future<void> _onLoadCalendarEvents(
    LoadCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      emit(const CalendarLoading());

      final response = await calendarApi.listEvents(
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );

      if (response.status == 'success' && response.result != null) {
        final result = response.result;
        final events = (result['events'] as List?)
                ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        // Parse conflict info if present
        ConflictInfo? conflictInfo;
        if (result['has_conflicts'] == true && result['conflicts'] != null) {
          conflictInfo = ConflictInfo.fromJson(result as Map<String, dynamic>);
        }

        emit(CalendarLoaded(events: events, conflictInfo: conflictInfo));
      } else {
        emit(CalendarError(
          'Failed to load events',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(CalendarError('Error loading events', details: e.toString()));
    }
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CalendarLoaded) {
        emit(const CalendarLoading());
      }

      final response = await calendarApi.createEvent(event.request);

      if (response.status == 'success' && response.result != null) {
        // Reload events to get the updated list
        add(const RefreshCalendarEvents());

        emit(CalendarOperationSuccess(
          message: 'Event created successfully',
          events: currentState is CalendarLoaded ? currentState.events : [],
        ));
      } else {
        emit(CalendarError(
          'Failed to create event',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(CalendarError('Error creating event', details: e.toString()));
    }
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CalendarLoaded) {
        emit(const CalendarLoading());
      }

      final response = await calendarApi.updateEvent(event.request);

      if (response.status == 'success') {
        // Reload events to get the updated list
        add(const RefreshCalendarEvents());

        emit(CalendarOperationSuccess(
          message: 'Event updated successfully',
          events: currentState is CalendarLoaded ? currentState.events : [],
        ));
      } else {
        emit(CalendarError(
          'Failed to update event',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(CalendarError('Error updating event', details: e.toString()));
    }
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CalendarLoaded) {
        emit(const CalendarLoading());
      }

      final response = await calendarApi.deleteEvent(event.request);

      if (response.status == 'success') {
        // Reload events to get the updated list
        add(const RefreshCalendarEvents());

        emit(CalendarOperationSuccess(
          message: 'Event deleted successfully',
          events: currentState is CalendarLoaded ? currentState.events : [],
        ));
      } else {
        emit(CalendarError(
          'Failed to delete event',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(CalendarError('Error deleting event', details: e.toString()));
    }
  }

  Future<void> _onRefreshCalendarEvents(
    RefreshCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    // Reload events without showing loading state
    final currentState = state;
    DateTime? startDate;
    DateTime? endDate;

    // If we have a current state with events, use a reasonable date range
    if (currentState is CalendarLoaded) {
      startDate = DateTime.now().subtract(const Duration(days: 30));
      endDate = DateTime.now().add(const Duration(days: 90));
    }

    add(LoadCalendarEvents(
      startDate: startDate,
      endDate: endDate,
    ));
  }

  // Real-time notification handlers
  void _onCalendarEventAdded(
    CalendarEventAdded event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final updatedEvents = List<CalendarEvent>.from(currentState.events)
        ..add(event.event);
      emit(currentState.copyWith(events: updatedEvents));
    }
  }

  void _onCalendarEventUpdated(
    CalendarEventUpdated event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final updatedEvents = currentState.events.map((e) {
        return e.id == event.event.id ? event.event : e;
      }).toList();
      emit(currentState.copyWith(events: updatedEvents));
    }
  }

  void _onCalendarEventDeleted(
    CalendarEventDeleted event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final updatedEvents = currentState.events
          .where((e) => e.id != event.eventId)
          .toList();
      emit(currentState.copyWith(events: updatedEvents));
    }
  }
}
