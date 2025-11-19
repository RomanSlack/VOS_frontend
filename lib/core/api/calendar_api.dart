import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/calendar_models.dart';

part 'calendar_api.g.dart';

@RestApi(baseUrl: '')
abstract class CalendarApi {
  factory CalendarApi(Dio dio, {String? baseUrl}) = _CalendarApi;

  // Execute calendar and reminder tools via the API Gateway
  @POST('/api/v1/tools/execute')
  Future<ToolExecutionResponse> executeTool(@Body() ToolExecutionRequest request);

  // Subscribe to app interactions (SSE)
  @GET('/api/v1/notifications/app-interaction')
  Future<HttpResponse> subscribeToNotifications({
    @Query('agent_id') String? agentId,
    @Query('app_name') String? appName,
  });
}

/// Helper class to simplify calendar tool execution
class CalendarToolHelper {
  final CalendarApi _api;

  CalendarToolHelper(this._api);

  // =========================================================================
  // Calendar Event Tools
  // =========================================================================

  Future<ToolExecutionResponse> createEvent(CreateEventRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'calendar_agent',
        toolName: 'create_calendar_event',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> listEvents({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['start_date'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate.toUtc().toIso8601String();
    }
    if (limit != null) {
      params['limit'] = limit;
    }

    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'calendar_agent',
        toolName: 'list_calendar_events',
        parameters: params,
      ),
    );
  }

  Future<ToolExecutionResponse> updateEvent(UpdateEventRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'calendar_agent',
        toolName: 'update_calendar_event',
        parameters: request.toJson(),
      ),
    );
  }

  Future<ToolExecutionResponse> deleteEvent(DeleteEventRequest request) {
    return _api.executeTool(
      ToolExecutionRequest(
        agentId: 'calendar_agent',
        toolName: 'delete_calendar_event',
        parameters: request.toJson(),
      ),
    );
  }
}
