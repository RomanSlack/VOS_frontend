import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/api/calendar_api.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/reminders/bloc/reminders_event.dart';
import 'package:vos_app/features/reminders/bloc/reminders_state.dart';

class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  final CalendarToolHelper calendarApi;

  RemindersBloc(this.calendarApi) : super(const RemindersInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<CreateReminder>(_onCreateReminder);
    on<CreateTimer>(_onCreateTimer);
    on<CreateAlarm>(_onCreateAlarm);
    on<EditReminder>(_onEditReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<RefreshReminders>(_onRefreshReminders);
    on<SilentRefreshReminders>(_onSilentRefreshReminders);
    on<ReminderTriggered>(_onReminderTriggered);
    on<DismissTriggeredReminder>(_onDismissTriggeredReminder);
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      emit(const RemindersLoading());

      final response = await calendarApi.listReminders(
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );

      if (response.status == 'success' && response.result != null) {
        final reminders = (response.result['reminders'] as List?)
                ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        emit(RemindersLoaded(reminders: reminders));
      } else {
        emit(RemindersError(
          'Failed to load reminders',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error loading reminders', details: e.toString()));
    }
  }

  Future<void> _onCreateReminder(
    CreateReminder event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! RemindersLoaded) {
        emit(const RemindersLoading());
      }

      final response = await calendarApi.createReminder(event.request);

      if (response.status == 'success') {
        // Reload reminders to get the updated list
        add(const RefreshReminders());

        emit(RemindersOperationSuccess(
          message: 'Reminder created successfully',
          reminders: currentState is RemindersLoaded ? currentState.reminders : [],
        ));
      } else {
        emit(RemindersError(
          'Failed to create reminder',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error creating reminder', details: e.toString()));
    }
  }

  Future<void> _onCreateTimer(
    CreateTimer event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! RemindersLoaded) {
        emit(const RemindersLoading());
      }

      final response = await calendarApi.createTimer(
        title: event.title,
        duration: event.duration,
        description: event.description,
      );

      if (response.status == 'success') {
        // Reload reminders to get the updated list
        add(const RefreshReminders());

        emit(RemindersOperationSuccess(
          message: 'Timer created successfully',
          reminders: currentState is RemindersLoaded ? currentState.reminders : [],
        ));
      } else {
        emit(RemindersError(
          'Failed to create timer',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error creating timer', details: e.toString()));
    }
  }

  Future<void> _onCreateAlarm(
    CreateAlarm event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! RemindersLoaded) {
        emit(const RemindersLoading());
      }

      final response = await calendarApi.createAlarm(
        title: event.title,
        time: event.time,
        description: event.description,
      );

      if (response.status == 'success') {
        // Reload reminders to get the updated list
        add(const RefreshReminders());

        emit(RemindersOperationSuccess(
          message: 'Alarm created successfully',
          reminders: currentState is RemindersLoaded ? currentState.reminders : [],
        ));
      } else {
        emit(RemindersError(
          'Failed to create alarm',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error creating alarm', details: e.toString()));
    }
  }

  Future<void> _onEditReminder(
    EditReminder event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! RemindersLoaded) {
        emit(const RemindersLoading());
      }

      final response = await calendarApi.editReminder(event.request);

      if (response.status == 'success') {
        // Reload reminders to get the updated list
        add(const RefreshReminders());

        emit(RemindersOperationSuccess(
          message: 'Reminder updated successfully',
          reminders: currentState is RemindersLoaded ? currentState.reminders : [],
        ));
      } else {
        emit(RemindersError(
          'Failed to update reminder',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error updating reminder', details: e.toString()));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! RemindersLoaded) {
        emit(const RemindersLoading());
      }

      final response = await calendarApi.deleteReminder(event.reminderId);

      if (response.status == 'success') {
        // Reload reminders to get the updated list
        add(const RefreshReminders());

        emit(RemindersOperationSuccess(
          message: 'Reminder deleted successfully',
          reminders: currentState is RemindersLoaded ? currentState.reminders : [],
        ));
      } else {
        emit(RemindersError(
          'Failed to delete reminder',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(RemindersError('Error deleting reminder', details: e.toString()));
    }
  }

  Future<void> _onRefreshReminders(
    RefreshReminders event,
    Emitter<RemindersState> emit,
  ) async {
    // Reload reminders without showing loading state
    DateTime? startDate;
    DateTime? endDate;

    // Use a reasonable date range
    startDate = DateTime.now().subtract(const Duration(days: 7));
    endDate = DateTime.now().add(const Duration(days: 90));

    add(SilentRefreshReminders(
      startDate: startDate,
      endDate: endDate,
    ));
  }

  Future<void> _onSilentRefreshReminders(
    SilentRefreshReminders event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      // Keep current state while loading (no loading screen!)
      final currentState = state;

      final response = await calendarApi.listReminders(
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );

      if (response.status == 'success' && response.result != null) {
        final reminders = (response.result['reminders'] as List?)
                ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        // Preserve triggered reminders from current state
        final triggeredReminders = currentState is RemindersLoaded
            ? currentState.triggeredReminders
            : <Reminder>[];

        emit(RemindersLoaded(
          reminders: reminders,
          triggeredReminders: triggeredReminders,
        ));
      }
      // Silently fail - keep current state if refresh fails
    } catch (e) {
      // Silently fail - don't show error on background refresh
    }
  }

  void _onReminderTriggered(
    ReminderTriggered event,
    Emitter<RemindersState> emit,
  ) {
    final currentState = state;
    if (currentState is RemindersLoaded) {
      final updatedTriggered = List<Reminder>.from(currentState.triggeredReminders)
        ..add(event.reminder);
      emit(currentState.copyWith(triggeredReminders: updatedTriggered));
    }
  }

  void _onDismissTriggeredReminder(
    DismissTriggeredReminder event,
    Emitter<RemindersState> emit,
  ) {
    final currentState = state;
    if (currentState is RemindersLoaded) {
      final updatedTriggered = currentState.triggeredReminders
          .where((r) => r.id != event.reminderId)
          .toList();
      emit(currentState.copyWith(triggeredReminders: updatedTriggered));
    }
  }
}
