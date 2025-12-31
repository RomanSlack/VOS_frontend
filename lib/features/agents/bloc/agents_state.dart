import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/social_models.dart';

abstract class AgentsState extends Equatable {
  const AgentsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AgentsInitial extends AgentsState {
  const AgentsInitial();
}

/// Loading agents
class AgentsLoading extends AgentsState {
  const AgentsLoading();
}

/// Agents loaded successfully
class AgentsLoaded extends AgentsState {
  final List<AgentProfileDto> agents;
  final AgentProfileDto? selectedAgent;
  final AgentHealthDto? selectedAgentHealth;
  final List<AgentStoryDto> selectedAgentStories;
  final bool onlineOnlyFilter;
  final int onlineCount;

  const AgentsLoaded({
    required this.agents,
    this.selectedAgent,
    this.selectedAgentHealth,
    this.selectedAgentStories = const [],
    this.onlineOnlyFilter = false,
    this.onlineCount = 0,
  });

  @override
  List<Object?> get props => [
        agents,
        selectedAgent,
        selectedAgentHealth,
        selectedAgentStories,
        onlineOnlyFilter,
        onlineCount,
      ];

  AgentsLoaded copyWith({
    List<AgentProfileDto>? agents,
    AgentProfileDto? selectedAgent,
    bool clearSelectedAgent = false,
    AgentHealthDto? selectedAgentHealth,
    List<AgentStoryDto>? selectedAgentStories,
    bool? onlineOnlyFilter,
    int? onlineCount,
  }) {
    return AgentsLoaded(
      agents: agents ?? this.agents,
      selectedAgent: clearSelectedAgent ? null : (selectedAgent ?? this.selectedAgent),
      selectedAgentHealth: clearSelectedAgent ? null : (selectedAgentHealth ?? this.selectedAgentHealth),
      selectedAgentStories: clearSelectedAgent ? const [] : (selectedAgentStories ?? this.selectedAgentStories),
      onlineOnlyFilter: onlineOnlyFilter ?? this.onlineOnlyFilter,
      onlineCount: onlineCount ?? this.onlineCount,
    );
  }

  /// Get online agents only
  List<AgentProfileDto> get onlineAgents =>
      agents.where((a) => a.isOnline).toList();

  /// Get offline agents only
  List<AgentProfileDto> get offlineAgents =>
      agents.where((a) => !a.isOnline).toList();

  /// Get filtered list based on current filter
  List<AgentProfileDto> get filteredAgents =>
      onlineOnlyFilter ? onlineAgents : agents;
}

/// Error state
class AgentsError extends AgentsState {
  final String message;
  final String? details;

  const AgentsError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}
