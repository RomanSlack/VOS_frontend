import 'package:json_annotation/json_annotation.dart';

part 'memory_models.g.dart';

// Request Models
@JsonSerializable()
class VisualizationRequest {
  final String method; // "umap", "pca", "tsne"
  final int dimensions; // 2 or 3
  @JsonKey(name: 'memory_type')
  final String? memoryType;
  final String? scope;
  @JsonKey(name: 'agent_id')
  final String? agentId;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  final List<String>? tags;
  @JsonKey(name: 'min_importance')
  final double? minImportance;
  @JsonKey(name: 'min_confidence')
  final double? minConfidence;
  final int limit;

  VisualizationRequest({
    required this.method,
    required this.dimensions,
    this.memoryType,
    this.scope,
    this.agentId,
    this.sessionId,
    this.tags,
    this.minImportance,
    this.minConfidence,
    this.limit = 500,
  });

  factory VisualizationRequest.fromJson(Map<String, dynamic> json) =>
      _$VisualizationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VisualizationRequestToJson(this);
}

// Response Models
@JsonSerializable()
class VisualizationPoint {
  final String id;
  final double x;
  final double y;
  final double? z;
  final String content;
  @JsonKey(name: 'memory_type')
  final String memoryType;
  final double importance;
  final double confidence;
  final List<String> tags;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'access_count')
  final int accessCount;
  @JsonKey(name: 'search_score')
  final double? searchScore;
  @JsonKey(name: 'agent_id')
  final String? agentId;
  final String? scope;

  VisualizationPoint({
    required this.id,
    required this.x,
    required this.y,
    this.z,
    required this.content,
    required this.memoryType,
    required this.importance,
    required this.confidence,
    this.tags = const [],
    this.createdAt,
    this.accessCount = 0,
    this.searchScore,
    this.agentId,
    this.scope,
  });

  factory VisualizationPoint.fromJson(Map<String, dynamic> json) =>
      _$VisualizationPointFromJson(json);
  Map<String, dynamic> toJson() => _$VisualizationPointToJson(this);
}

@JsonSerializable()
class VisualizationResponse {
  final String status;
  final int count;
  final String method;
  final int dimensions;
  final List<VisualizationPoint> points;
  final Map<String, dynamic> filters;

  VisualizationResponse({
    required this.status,
    required this.count,
    required this.method,
    required this.dimensions,
    required this.points,
    required this.filters,
  });

  factory VisualizationResponse.fromJson(Map<String, dynamic> json) =>
      _$VisualizationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VisualizationResponseToJson(this);
}

@JsonSerializable()
class StatisticsByType {
  @JsonKey(name: 'memory_type')
  final String memoryType;
  final int count;
  @JsonKey(name: 'avg_importance')
  final double avgImportance;
  @JsonKey(name: 'avg_confidence')
  final double avgConfidence;

  StatisticsByType({
    required this.memoryType,
    required this.count,
    required this.avgImportance,
    required this.avgConfidence,
  });

  factory StatisticsByType.fromJson(Map<String, dynamic> json) =>
      _$StatisticsByTypeFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsByTypeToJson(this);
}

@JsonSerializable()
class StatisticsResponse {
  final String status;
  @JsonKey(name: 'total_memories')
  final int totalMemories;
  @JsonKey(name: 'by_type')
  final List<StatisticsByType> byType;
  @JsonKey(name: 'by_scope')
  final Map<String, int> byScope;
  @JsonKey(name: 'top_tags')
  final List<Map<String, dynamic>> topTags;
  @JsonKey(name: 'importance_distribution')
  final Map<String, int> importanceDistribution;
  @JsonKey(name: 'confidence_distribution')
  final Map<String, int> confidenceDistribution;
  @JsonKey(name: 'date_range')
  final Map<String, String?> dateRange;

  StatisticsResponse({
    required this.status,
    required this.totalMemories,
    required this.byType,
    required this.byScope,
    required this.topTags,
    required this.importanceDistribution,
    required this.confidenceDistribution,
    required this.dateRange,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsResponseToJson(this);
}

// Memory Type Enum
enum MemoryType {
  @JsonValue('user_preference')
  userPreference,
  @JsonValue('user_fact')
  userFact,
  @JsonValue('conversation_context')
  conversationContext,
  @JsonValue('agent_procedure')
  agentProcedure,
  @JsonValue('knowledge')
  knowledge,
  @JsonValue('event_pattern')
  eventPattern,
  @JsonValue('error_handling')
  errorHandling,
  @JsonValue('proactive_action')
  proactiveAction,
}

// Utility extensions
extension MemoryTypeExtension on MemoryType {
  String get displayName {
    switch (this) {
      case MemoryType.userPreference:
        return 'User Preference';
      case MemoryType.userFact:
        return 'User Fact';
      case MemoryType.conversationContext:
        return 'Conversation';
      case MemoryType.agentProcedure:
        return 'Procedure';
      case MemoryType.knowledge:
        return 'Knowledge';
      case MemoryType.eventPattern:
        return 'Event Pattern';
      case MemoryType.errorHandling:
        return 'Error Handling';
      case MemoryType.proactiveAction:
        return 'Proactive Action';
    }
  }

  String get value {
    switch (this) {
      case MemoryType.userPreference:
        return 'user_preference';
      case MemoryType.userFact:
        return 'user_fact';
      case MemoryType.conversationContext:
        return 'conversation_context';
      case MemoryType.agentProcedure:
        return 'agent_procedure';
      case MemoryType.knowledge:
        return 'knowledge';
      case MemoryType.eventPattern:
        return 'event_pattern';
      case MemoryType.errorHandling:
        return 'error_handling';
      case MemoryType.proactiveAction:
        return 'proactive_action';
    }
  }
}
