import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/core/services/social_service.dart';
import 'package:vos_app/features/agents/bloc/agents_event.dart';
import 'package:vos_app/features/agents/bloc/agents_state.dart';

final _log = Logger('AgentsBloc');

class AgentsBloc extends Bloc<AgentsEvent, AgentsState> {
  final SocialService _socialService;

  AgentsBloc(this._socialService) : super(const AgentsInitial()) {
    on<LoadAgents>(_onLoadAgents);
    on<RefreshAgents>(_onRefreshAgents);
    on<SelectAgent>(_onSelectAgent);
    on<ClearSelectedAgent>(_onClearSelectedAgent);
    on<AgentHealthUpdated>(_onAgentHealthUpdated);
    on<FilterOnlineAgents>(_onFilterOnlineAgents);
  }

  Future<void> _onLoadAgents(
    LoadAgents event,
    Emitter<AgentsState> emit,
  ) async {
    try {
      final shouldShowLoading = state is! AgentsLoaded;
      if (shouldShowLoading) {
        emit(const AgentsLoading());
      }

      final agents = await _socialService.getAgents(
        forceRefresh: event.forceRefresh,
      );

      final onlineCount = agents.where((a) => a.isOnline).length;

      if (state is AgentsLoaded) {
        emit((state as AgentsLoaded).copyWith(
          agents: agents,
          onlineCount: onlineCount,
        ));
      } else {
        emit(AgentsLoaded(
          agents: agents,
          onlineCount: onlineCount,
        ));
      }
    } catch (e) {
      _log.severe('Failed to load agents: $e');
      emit(AgentsError('Failed to load agents', details: e.toString()));
    }
  }

  Future<void> _onRefreshAgents(
    RefreshAgents event,
    Emitter<AgentsState> emit,
  ) async {
    add(const LoadAgents(forceRefresh: true));
  }

  Future<void> _onSelectAgent(
    SelectAgent event,
    Emitter<AgentsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AgentsLoaded) return;

    try {
      // Find agent in current list
      final agent = currentState.agents
          .where((a) => a.agentId == event.agentId)
          .firstOrNull;

      if (agent == null) {
        // Fetch from API
        final fetchedAgent = await _socialService.getAgentProfile(event.agentId);
        emit(currentState.copyWith(selectedAgent: fetchedAgent));
      } else {
        emit(currentState.copyWith(selectedAgent: agent));
      }

      // Load additional data
      final health = await _socialService.getAgentHealth(event.agentId);
      final stories = await _socialService.getAgentStories(event.agentId);

      if (state is AgentsLoaded) {
        emit((state as AgentsLoaded).copyWith(
          selectedAgentHealth: health,
          selectedAgentStories: stories,
        ));
      }
    } catch (e) {
      _log.severe('Failed to select agent: $e');
      // Don't emit error state, just log it
    }
  }

  void _onClearSelectedAgent(
    ClearSelectedAgent event,
    Emitter<AgentsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AgentsLoaded) return;

    emit(currentState.copyWith(clearSelectedAgent: true));
  }

  void _onAgentHealthUpdated(
    AgentHealthUpdated event,
    Emitter<AgentsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AgentsLoaded) return;

    final updatedAgents = currentState.agents.map((agent) {
      if (agent.agentId == event.update.agentId) {
        return AgentProfileDto(
          agentId: agent.agentId,
          displayName: agent.displayName,
          description: agent.description,
          avatarUrl: agent.avatarUrl,
          isOnline: event.update.isOnline,
          lastSeen: event.update.lastHeartbeat,
          currentStatus: agent.currentStatus,
          capabilities: agent.capabilities,
        );
      }
      return agent;
    }).toList();

    final onlineCount = updatedAgents.where((a) => a.isOnline).length;

    emit(currentState.copyWith(
      agents: updatedAgents,
      onlineCount: onlineCount,
    ));
  }

  void _onFilterOnlineAgents(
    FilterOnlineAgents event,
    Emitter<AgentsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AgentsLoaded) return;

    emit(currentState.copyWith(onlineOnlyFilter: event.onlineOnly));
  }
}
