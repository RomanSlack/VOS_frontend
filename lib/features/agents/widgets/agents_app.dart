import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/agents/bloc/agents_bloc.dart';
import 'package:vos_app/features/agents/bloc/agents_event.dart';
import 'package:vos_app/features/agents/bloc/agents_state.dart';
import 'package:vos_app/features/agents/widgets/agent_profile_card.dart';
import 'package:vos_app/features/agents/widgets/agent_profile_detail.dart';
import 'package:vos_app/features/conversations/bloc/conversations_bloc.dart';
import 'package:vos_app/features/conversations/bloc/conversations_event.dart';

class AgentsApp extends StatefulWidget {
  const AgentsApp({super.key});

  @override
  State<AgentsApp> createState() => _AgentsAppState();
}

class _AgentsAppState extends State<AgentsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentsBloc>().add(const LoadAgents());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: BlocBuilder<AgentsBloc, AgentsState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isSplitView = constraints.maxWidth > 600;

              if (isSplitView) {
                return _buildSplitView(state);
              } else {
                return _buildMobileView(state);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSplitView(AgentsState state) {
    final hasSelection = state is AgentsLoaded && state.selectedAgent != null;

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _buildAgentsList(state),
        ),
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        Expanded(
          child: hasSelection
              ? AgentProfileDetail(
                  agent: (state as AgentsLoaded).selectedAgent!,
                  health: state.selectedAgentHealth,
                  stories: state.selectedAgentStories,
                  onStartDm: _startDmWithAgent,
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildMobileView(AgentsState state) {
    final hasSelection = state is AgentsLoaded && state.selectedAgent != null;

    if (hasSelection) {
      return WillPopScope(
        onWillPop: () async {
          context.read<AgentsBloc>().add(const ClearSelectedAgent());
          return false;
        },
        child: AgentProfileDetail(
          agent: (state as AgentsLoaded).selectedAgent!,
          health: state.selectedAgentHealth,
          stories: state.selectedAgentStories,
          showBackButton: true,
          onBack: () {
            context.read<AgentsBloc>().add(const ClearSelectedAgent());
          },
          onStartDm: _startDmWithAgent,
        ),
      );
    }

    return _buildAgentsList(state);
  }

  Widget _buildAgentsList(AgentsState state) {
    return Column(
      children: [
        _buildHeader(state),
        Expanded(
          child: _buildList(state),
        ),
      ],
    );
  }

  Widget _buildHeader(AgentsState state) {
    final onlineCount = state is AgentsLoaded ? state.onlineCount : 0;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.smart_toy_outlined,
            color: Color(0xFFEDEDED),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Agents',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$onlineCount online',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF757575)),
            onPressed: () {
              context.read<AgentsBloc>().add(const RefreshAgents());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(AgentsState state) {
    if (state is AgentsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF757575)),
      );
    }

    if (state is AgentsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<AgentsBloc>().add(const RefreshAgents());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is! AgentsLoaded) {
      return const SizedBox.shrink();
    }

    final agents = state.filteredAgents;

    // Sort: online first, then by name
    agents.sort((a, b) {
      if (a.isOnline != b.isOnline) {
        return a.isOnline ? -1 : 1;
      }
      return a.displayName.compareTo(b.displayName);
    });

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AgentsBloc>().add(const RefreshAgents());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          final isSelected = state.selectedAgent?.agentId == agent.agentId;

          return AgentProfileCard(
            agent: agent,
            isSelected: isSelected,
            onTap: () {
              context.read<AgentsBloc>().add(SelectAgent(agent.agentId));
            },
            onStartDm: () => _startDmWithAgent(agent.agentId),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            color: Colors.white.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select an agent',
            style: TextStyle(color: Color(0xFF757575), fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'to view their profile and start a chat',
            style: TextStyle(color: Color(0xFF616161), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _startDmWithAgent(String agentId) {
    context.read<ConversationsBloc>().add(StartDmWithAgent(agentId));
    // TODO: Navigate to conversations
  }
}
