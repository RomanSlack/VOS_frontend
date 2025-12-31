import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';

abstract class AgentsEvent extends Equatable {
  const AgentsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all agents with their status
class LoadAgents extends AgentsEvent {
  final bool forceRefresh;

  const LoadAgents({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Refresh agents list
class RefreshAgents extends AgentsEvent {
  const RefreshAgents();
}

/// Select an agent to view profile
class SelectAgent extends AgentsEvent {
  final String agentId;

  const SelectAgent(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

/// Clear selected agent
class ClearSelectedAgent extends AgentsEvent {
  const ClearSelectedAgent();
}

/// Agent health status updated (from WebSocket)
class AgentHealthUpdated extends AgentsEvent {
  final AgentHealthUpdatePayload update;

  const AgentHealthUpdated(this.update);

  @override
  List<Object?> get props => [update];
}

/// Filter agents by online status
class FilterOnlineAgents extends AgentsEvent {
  final bool onlineOnly;

  const FilterOnlineAgents(this.onlineOnly);

  @override
  List<Object?> get props => [onlineOnly];
}
