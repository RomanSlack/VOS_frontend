import 'package:json_annotation/json_annotation.dart';

part 'calendar_models.g.dart';

// ============================================================================
// Calendar Event Models
// ============================================================================

@JsonSerializable()
class CalendarEvent {
  final String id;
  final String title;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  final String? description;
  final String? location;
  @JsonKey(name: 'all_day')
  final bool allDay;
  @JsonKey(name: 'recurrence_rule')
  final RecurrenceRule? recurrenceRule;
  @JsonKey(name: 'exception_dates')
  final List<String>? exceptionDates;
  @JsonKey(name: 'auto_reminders')
  final List<int>? autoReminders;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.allDay = false,
    this.recurrenceRule,
    this.exceptionDates,
    this.autoReminders,
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? location,
    bool? allDay,
    RecurrenceRule? recurrenceRule,
    List<String>? exceptionDates,
    List<int>? autoReminders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      location: location ?? this.location,
      allDay: allDay ?? this.allDay,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      exceptionDates: exceptionDates ?? this.exceptionDates,
      autoReminders: autoReminders ?? this.autoReminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isRecurring => recurrenceRule != null;
}

@JsonSerializable()
class RecurrenceRule {
  final String freq;
  final int? interval;
  final int? count;
  final DateTime? until;
  @JsonKey(name: 'by_weekday')
  final List<String>? byWeekday;
  @JsonKey(name: 'by_monthday')
  final List<int>? byMonthday;
  @JsonKey(name: 'by_month')
  final List<int>? byMonth;

  RecurrenceRule({
    required this.freq,
    this.interval,
    this.count,
    this.until,
    this.byWeekday,
    this.byMonthday,
    this.byMonth,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceRuleFromJson(json);

  Map<String, dynamic> toJson() => _$RecurrenceRuleToJson(this);

  String toHumanReadable() {
    final buffer = StringBuffer();

    switch (freq.toUpperCase()) {
      case 'DAILY':
        if (interval != null && interval! > 1) {
          buffer.write('Every $interval days');
        } else {
          buffer.write('Daily');
        }
        break;
      case 'WEEKLY':
        if (interval != null && interval! > 1) {
          buffer.write('Every $interval weeks');
        } else {
          buffer.write('Weekly');
        }
        if (byWeekday != null && byWeekday!.isNotEmpty) {
          buffer.write(' on ${byWeekday!.join(', ')}');
        }
        break;
      case 'MONTHLY':
        if (interval != null && interval! > 1) {
          buffer.write('Every $interval months');
        } else {
          buffer.write('Monthly');
        }
        if (byMonthday != null && byMonthday!.isNotEmpty) {
          buffer.write(' on day ${byMonthday!.join(', ')}');
        }
        break;
      case 'YEARLY':
        if (interval != null && interval! > 1) {
          buffer.write('Every $interval years');
        } else {
          buffer.write('Yearly');
        }
        break;
      default:
        buffer.write(freq);
    }

    if (count != null) {
      buffer.write(', $count times');
    } else if (until != null) {
      buffer.write(' until ${until!.toLocal().toString().split(' ')[0]}');
    }

    return buffer.toString();
  }
}

// ============================================================================
// API Request/Response Models
// ============================================================================

@JsonSerializable()
class CreateEventRequest {
  final String title;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  final String? description;
  final String? location;
  @JsonKey(name: 'all_day')
  final bool? allDay;
  @JsonKey(name: 'recurrence_rule')
  final RecurrenceRule? recurrenceRule;
  @JsonKey(name: 'auto_reminders')
  final List<int>? autoReminders;

  CreateEventRequest({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.allDay,
    this.recurrenceRule,
    this.autoReminders,
  });

  factory CreateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEventRequestToJson(this);
}

@JsonSerializable()
class UpdateEventRequest {
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'update_mode')
  final String updateMode; // 'this' | 'this_and_future' | 'all'
  @JsonKey(name: 'instance_date')
  final String? instanceDate;
  final String? title;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  final String? description;
  final String? location;
  @JsonKey(name: 'all_day')
  final bool? allDay;
  @JsonKey(name: 'recurrence_rule')
  final RecurrenceRule? recurrenceRule;
  @JsonKey(name: 'auto_reminders')
  final List<int>? autoReminders;

  UpdateEventRequest({
    required this.eventId,
    required this.updateMode,
    this.instanceDate,
    this.title,
    this.startTime,
    this.endTime,
    this.description,
    this.location,
    this.allDay,
    this.recurrenceRule,
    this.autoReminders,
  });

  factory UpdateEventRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateEventRequestToJson(this);
}

@JsonSerializable()
class DeleteEventRequest {
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'delete_mode')
  final String deleteMode; // 'this' | 'this_and_future' | 'all'
  @JsonKey(name: 'instance_date')
  final String? instanceDate;

  DeleteEventRequest({
    required this.eventId,
    required this.deleteMode,
    this.instanceDate,
  });

  factory DeleteEventRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteEventRequestToJson(this);
}

@JsonSerializable()
class ListEventsRequest {
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'end_date')
  final String? endDate;
  final int? limit;

  ListEventsRequest({
    this.startDate,
    this.endDate,
    this.limit,
  });

  factory ListEventsRequest.fromJson(Map<String, dynamic> json) =>
      _$ListEventsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ListEventsRequestToJson(this);
}

// ============================================================================
// Tool Execution Models
// ============================================================================

@JsonSerializable()
class ToolExecutionRequest {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'tool_name')
  final String toolName;
  final Map<String, dynamic> parameters;

  ToolExecutionRequest({
    required this.agentId,
    required this.toolName,
    required this.parameters,
  });

  factory ToolExecutionRequest.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionRequestToJson(this);
}

@JsonSerializable()
class ToolExecutionResponse {
  final String status;
  final String? message;
  final dynamic result;
  @JsonKey(name: 'agent_id')
  final String? agentId;

  ToolExecutionResponse({
    required this.status,
    this.message,
    this.result,
    this.agentId,
  });

  factory ToolExecutionResponse.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionResponseToJson(this);
}

@JsonSerializable()
class EventsListResponse {
  final List<CalendarEvent> events;
  @JsonKey(name: 'has_conflicts')
  final bool? hasConflicts;
  final Map<String, dynamic>? conflicts;

  EventsListResponse({
    required this.events,
    this.hasConflicts,
    this.conflicts,
  });

  factory EventsListResponse.fromJson(Map<String, dynamic> json) =>
      _$EventsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EventsListResponseToJson(this);
}

// ============================================================================
// Notification Models
// ============================================================================

@JsonSerializable()
class AppNotification {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'app_name')
  final String appName;
  final String action;
  final Map<String, dynamic> result;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  AppNotification({
    required this.agentId,
    required this.appName,
    required this.action,
    required this.result,
    this.sessionId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

// ============================================================================
// Conflict Detection Models
// ============================================================================

@JsonSerializable()
class ConflictInfo {
  @JsonKey(name: 'has_conflicts')
  final bool hasConflicts;
  final List<ConflictDetail>? conflicts;

  ConflictInfo({
    required this.hasConflicts,
    this.conflicts,
  });

  factory ConflictInfo.fromJson(Map<String, dynamic> json) =>
      _$ConflictInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ConflictInfoToJson(this);
}

@JsonSerializable()
class ConflictDetail {
  @JsonKey(name: 'event_title')
  final String eventTitle;
  @JsonKey(name: 'conflict_count')
  final int conflictCount;
  @JsonKey(name: 'conflict_dates')
  final List<String> conflictDates;

  ConflictDetail({
    required this.eventTitle,
    required this.conflictCount,
    required this.conflictDates,
  });

  factory ConflictDetail.fromJson(Map<String, dynamic> json) =>
      _$ConflictDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ConflictDetailToJson(this);
}

// ============================================================================
// Reminder Models
// ============================================================================

@JsonSerializable()
class Reminder {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'trigger_time')
  final DateTime triggerTime;
  @JsonKey(name: 'is_event_attached')
  final bool isEventAttached;
  @JsonKey(name: 'event_title')
  final String? eventTitle;
  @JsonKey(name: 'event_id')
  final String? eventId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.triggerTime,
    this.isEventAttached = false,
    this.eventTitle,
    this.eventId,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);

  Map<String, dynamic> toJson() => _$ReminderToJson(this);
}
