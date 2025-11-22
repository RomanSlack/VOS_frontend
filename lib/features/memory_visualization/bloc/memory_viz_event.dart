import 'package:equatable/equatable.dart';

abstract class MemoryVizEvent extends Equatable {
  const MemoryVizEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisualization extends MemoryVizEvent {
  final String method; // "umap", "pca", "tsne"
  final int dimensions; // 2 or 3
  final String? memoryType;
  final String? scope;
  final String? agentId;
  final List<String>? tags;
  final double? minImportance;
  final double? minConfidence;
  final int limit;

  const LoadVisualization({
    this.method = "umap",
    this.dimensions = 2,
    this.memoryType,
    this.scope,
    this.agentId,
    this.tags,
    this.minImportance,
    this.minConfidence,
    this.limit = 500,
  });

  @override
  List<Object?> get props => [
        method,
        dimensions,
        memoryType,
        scope,
        agentId,
        tags,
        minImportance,
        minConfidence,
        limit,
      ];
}

class ToggleDimensions extends MemoryVizEvent {
  const ToggleDimensions();
}

class ChangeReductionMethod extends MemoryVizEvent {
  final String method;

  const ChangeReductionMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class SearchMemories extends MemoryVizEvent {
  final String query;

  const SearchMemories(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends MemoryVizEvent {
  const ClearSearch();
}

class UpdateFilters extends MemoryVizEvent {
  final String? memoryType;
  final String? scope;
  final double? minImportance;
  final double? minConfidence;
  final List<String>? tags;

  const UpdateFilters({
    this.memoryType,
    this.scope,
    this.minImportance,
    this.minConfidence,
    this.tags,
  });

  @override
  List<Object?> get props => [
        memoryType,
        scope,
        minImportance,
        minConfidence,
        tags,
      ];
}

class LoadStatistics extends MemoryVizEvent {
  const LoadStatistics();
}

class RefreshVisualization extends MemoryVizEvent {
  const RefreshVisualization();
}
