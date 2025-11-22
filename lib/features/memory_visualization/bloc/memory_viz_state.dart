import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/memory_models.dart';

abstract class MemoryVizState extends Equatable {
  const MemoryVizState();

  @override
  List<Object?> get props => [];
}

class MemoryVizInitial extends MemoryVizState {
  const MemoryVizInitial();
}

class MemoryVizLoading extends MemoryVizState {
  const MemoryVizLoading();
}

class MemoryVizLoaded extends MemoryVizState {
  final List<VisualizationPoint> points;
  final String method;
  final int dimensions;
  final Map<String, dynamic> filters;
  final Set<String> highlightedIds; // For search highlighting
  final StatisticsResponse? statistics;

  const MemoryVizLoaded({
    required this.points,
    required this.method,
    required this.dimensions,
    required this.filters,
    this.highlightedIds = const {},
    this.statistics,
  });

  @override
  List<Object?> get props => [
        points,
        method,
        dimensions,
        filters,
        highlightedIds,
        statistics,
      ];

  MemoryVizLoaded copyWith({
    List<VisualizationPoint>? points,
    String? method,
    int? dimensions,
    Map<String, dynamic>? filters,
    Set<String>? highlightedIds,
    StatisticsResponse? statistics,
  }) {
    return MemoryVizLoaded(
      points: points ?? this.points,
      method: method ?? this.method,
      dimensions: dimensions ?? this.dimensions,
      filters: filters ?? this.filters,
      highlightedIds: highlightedIds ?? this.highlightedIds,
      statistics: statistics ?? this.statistics,
    );
  }
}

class MemoryVizError extends MemoryVizState {
  final String message;
  final String? details;

  const MemoryVizError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}
