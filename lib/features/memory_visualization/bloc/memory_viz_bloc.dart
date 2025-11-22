import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/api/memory_api.dart';
import 'package:vos_app/core/models/memory_models.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_event.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_state.dart';

class MemoryVizBloc extends Bloc<MemoryVizEvent, MemoryVizState> {
  final MemoryApi memoryApi;

  // Current filter state
  String _currentMethod = "umap";
  int _currentDimensions = 2;
  String? _currentMemoryType;
  String? _currentScope;
  double? _currentMinImportance;
  double? _currentMinConfidence;
  List<String>? _currentTags;

  MemoryVizBloc(this.memoryApi) : super(const MemoryVizInitial()) {
    on<LoadVisualization>(_onLoadVisualization);
    on<ToggleDimensions>(_onToggleDimensions);
    on<ChangeReductionMethod>(_onChangeReductionMethod);
    on<SearchMemories>(_onSearchMemories);
    on<ClearSearch>(_onClearSearch);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshVisualization>(_onRefreshVisualization);
  }

  Future<void> _onLoadVisualization(
    LoadVisualization event,
    Emitter<MemoryVizState> emit,
  ) async {
    try {
      // Don't show loading if we already have data (prevents flashing)
      final shouldShowLoading = state is! MemoryVizLoaded;
      if (shouldShowLoading) {
        emit(const MemoryVizLoading());
      }

      // Update current filter state
      _currentMethod = event.method;
      _currentDimensions = event.dimensions;
      _currentMemoryType = event.memoryType;
      _currentScope = event.scope;
      _currentMinImportance = event.minImportance;
      _currentMinConfidence = event.minConfidence;
      _currentTags = event.tags;

      // Create request
      final request = VisualizationRequest(
        method: event.method,
        dimensions: event.dimensions,
        memoryType: event.memoryType,
        scope: event.scope,
        agentId: event.agentId,
        tags: event.tags,
        minImportance: event.minImportance,
        minConfidence: event.minConfidence,
        limit: event.limit,
      );

      // Fetch visualization data
      final response = await memoryApi.getVisualization(request);

      if (response.status == 'success') {
        // Load statistics in parallel
        StatisticsResponse? statistics;
        try {
          statistics = await memoryApi.getStatistics();
        } catch (e) {
          // Statistics are optional, continue without them
          print('Failed to load statistics: $e');
        }

        emit(MemoryVizLoaded(
          points: response.points,
          method: response.method,
          dimensions: response.dimensions,
          filters: response.filters,
          statistics: statistics,
        ));
      } else {
        emit(const MemoryVizError('Failed to load visualization'));
      }
    } catch (e) {
      emit(MemoryVizError('Error loading visualization', details: e.toString()));
    }
  }

  Future<void> _onToggleDimensions(
    ToggleDimensions event,
    Emitter<MemoryVizState> emit,
  ) async {
    // Toggle between 2D and 3D
    final newDimensions = _currentDimensions == 2 ? 3 : 2;

    // Reload with new dimensions
    add(LoadVisualization(
      method: _currentMethod,
      dimensions: newDimensions,
      memoryType: _currentMemoryType,
      scope: _currentScope,
      tags: _currentTags,
      minImportance: _currentMinImportance,
      minConfidence: _currentMinConfidence,
    ));
  }

  Future<void> _onChangeReductionMethod(
    ChangeReductionMethod event,
    Emitter<MemoryVizState> emit,
  ) async {
    // Reload with new reduction method
    add(LoadVisualization(
      method: event.method,
      dimensions: _currentDimensions,
      memoryType: _currentMemoryType,
      scope: _currentScope,
      tags: _currentTags,
      minImportance: _currentMinImportance,
      minConfidence: _currentMinConfidence,
    ));
  }

  Future<void> _onSearchMemories(
    SearchMemories event,
    Emitter<MemoryVizState> emit,
  ) async {
    if (state is! MemoryVizLoaded) return;

    try {
      // Search for memories
      final results = await memoryApi.searchForVisualization(
        event.query,
        50,
      );

      if (results != null && results['status'] == 'success') {
        final searchResults = results['results'] as List;
        final highlightedIds = searchResults
            .map((r) => r['id'] as String)
            .toSet();

        // Update state with highlighted IDs
        final currentState = state as MemoryVizLoaded;
        emit(currentState.copyWith(highlightedIds: highlightedIds));
      }
    } catch (e) {
      // Don't emit error for search failure, just log it
      print('Search failed: $e');
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<MemoryVizState> emit,
  ) async {
    if (state is! MemoryVizLoaded) return;

    final currentState = state as MemoryVizLoaded;
    emit(currentState.copyWith(highlightedIds: {}));
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<MemoryVizState> emit,
  ) async {
    // Reload with new filters
    add(LoadVisualization(
      method: _currentMethod,
      dimensions: _currentDimensions,
      memoryType: event.memoryType ?? _currentMemoryType,
      scope: event.scope ?? _currentScope,
      tags: event.tags ?? _currentTags,
      minImportance: event.minImportance ?? _currentMinImportance,
      minConfidence: event.minConfidence ?? _currentMinConfidence,
    ));
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<MemoryVizState> emit,
  ) async {
    if (state is! MemoryVizLoaded) return;

    try {
      final statistics = await memoryApi.getStatistics();
      final currentState = state as MemoryVizLoaded;
      emit(currentState.copyWith(statistics: statistics));
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  Future<void> _onRefreshVisualization(
    RefreshVisualization event,
    Emitter<MemoryVizState> emit,
  ) async {
    // Reload with current settings
    add(LoadVisualization(
      method: _currentMethod,
      dimensions: _currentDimensions,
      memoryType: _currentMemoryType,
      scope: _currentScope,
      tags: _currentTags,
      minImportance: _currentMinImportance,
      minConfidence: _currentMinConfidence,
    ));
  }
}
