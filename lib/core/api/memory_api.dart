import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/memory_models.dart';

part 'memory_api.g.dart';

@RestApi(baseUrl: '')
abstract class MemoryApi {
  factory MemoryApi(Dio dio, {String? baseUrl}) = _MemoryApi;

  // Visualization endpoints
  @POST('/api/v1/memories/visualization/reduce')
  Future<VisualizationResponse> getVisualization(
    @Body() VisualizationRequest request,
  );

  @GET('/api/v1/memories/visualization/statistics')
  Future<StatisticsResponse> getStatistics();

  @GET('/api/v1/memories/visualization/search-for-viz')
  Future<dynamic> searchForVisualization(
    @Query('query') String query,
    @Query('limit') int limit,
  );

  // Regular memory endpoints
  @GET('/api/v1/memories/search')
  Future<dynamic> searchMemories(
    @Query('query') String query,
    @Query('limit') int limit,
  );

  @GET('/api/v1/memories/{memory_id}')
  Future<dynamic> getMemory(
    @Path('memory_id') String memoryId,
  );
}
