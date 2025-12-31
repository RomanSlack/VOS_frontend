import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/social_models.dart';
import 'package:vos_app/features/conversations/bloc/conversations_bloc.dart';
import 'package:vos_app/features/conversations/bloc/conversations_event.dart';
import 'package:vos_app/features/conversations/bloc/conversations_state.dart';
import 'package:vos_app/features/conversations/widgets/conversation_list_item.dart';
import 'package:vos_app/features/conversations/widgets/conversation_detail.dart';

class ConversationsApp extends StatefulWidget {
  const ConversationsApp({super.key});

  @override
  State<ConversationsApp> createState() => _ConversationsAppState();
}

class _ConversationsAppState extends State<ConversationsApp> {
  ConversationType? _filterType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load conversations when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationsBloc>().add(const LoadConversations());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: BlocConsumer<ConversationsBloc, ConversationsState>(
        listener: (context, state) {
          if (state is ConversationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          } else if (state is ConversationsOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Use split view on wider screens
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

  Widget _buildSplitView(ConversationsState state) {
    final hasSelection = state is ConversationsLoaded &&
        state.selectedConversation != null;

    return Row(
      children: [
        // Conversation list (fixed width)
        SizedBox(
          width: 320,
          child: _buildConversationList(state),
        ),
        // Divider
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        // Conversation detail
        Expanded(
          child: hasSelection
              ? ConversationDetail(
                  conversation: (state as ConversationsLoaded).selectedConversation!,
                  messages: state.messages,
                  isLoading: state.messagesLoading,
                  typingUsers: state.typingUsers,
                  isWebSocketConnected: state.isWebSocketConnected,
                  agentStatuses: state.agentStatuses,
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildMobileView(ConversationsState state) {
    final hasSelection = state is ConversationsLoaded &&
        state.selectedConversation != null;

    if (hasSelection) {
      return WillPopScope(
        onWillPop: () async {
          context.read<ConversationsBloc>().add(const ClearSelectedConversation());
          return false;
        },
        child: ConversationDetail(
          conversation: (state as ConversationsLoaded).selectedConversation!,
          messages: state.messages,
          isLoading: state.messagesLoading,
          typingUsers: state.typingUsers,
          showBackButton: true,
          onBack: () {
            context.read<ConversationsBloc>().add(const ClearSelectedConversation());
          },
          isWebSocketConnected: state.isWebSocketConnected,
          agentStatuses: state.agentStatuses,
        ),
      );
    }

    return _buildConversationList(state);
  }

  Widget _buildConversationList(ConversationsState state) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterTabs(),
        Expanded(
          child: _buildList(state),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
            Icons.chat_bubble_outline,
            color: Color(0xFFEDEDED),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Conversations',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF757575)),
            onPressed: _showNewConversationDialog,
            tooltip: 'New conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('DMs', ConversationType.dm),
          const SizedBox(width: 8),
          _buildFilterChip('Groups', ConversationType.group),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ConversationType? type) {
    final isSelected = _filterType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
        });
        context.read<ConversationsBloc>().add(FilterByType(type));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A4A4A)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFEDEDED)
                : const Color(0xFF757575),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildList(ConversationsState state) {
    if (state is ConversationsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF757575),
        ),
      );
    }

    if (state is ConversationsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade300,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<ConversationsBloc>().add(const RefreshConversations());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is! ConversationsLoaded) {
      return const SizedBox.shrink();
    }

    final conversations = state.conversations;

    if (conversations.isEmpty) {
      return _buildEmptyListState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConversationsBloc>().add(const RefreshConversations());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final isSelected =
              state.selectedConversation?.conversationId ==
                  conversation.conversationId;

          return ConversationListItem(
            conversation: conversation,
            isSelected: isSelected,
            onTap: () {
              context.read<ConversationsBloc>().add(
                    SelectConversation(conversation.conversationId),
                  );
            },
            onLongPress: () {
              _showConversationOptions(conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a chat with an agent',
            style: TextStyle(
              color: Color(0xFF616161),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewConversationDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4A),
              foregroundColor: const Color(0xFFEDEDED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a conversation',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'or start a new chat with an agent',
            style: TextStyle(
              color: Color(0xFF616161),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF303030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _NewConversationSheet(
        onStartDm: (agentId) {
          Navigator.pop(context);
          context.read<ConversationsBloc>().add(StartDmWithAgent(agentId));
        },
        onCreateGroup: (name, agentIds) {
          Navigator.pop(context);
          context.read<ConversationsBloc>().add(
                CreateGroup(name: name, agentIds: agentIds),
              );
        },
      ),
    );
  }

  void _showConversationOptions(ConversationDto conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF303030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.archive, color: Color(0xFF757575)),
            title: const Text(
              'Archive',
              style: TextStyle(color: Color(0xFFEDEDED)),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<ConversationsBloc>().add(
                    ArchiveConversation(conversation.conversationId),
                  );
            },
          ),
          if (conversation.conversationType == ConversationType.group)
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Leave Group',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<ConversationsBloc>().add(
                      LeaveConversation(conversation.conversationId),
                    );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NewConversationSheet extends StatefulWidget {
  final void Function(String agentId) onStartDm;
  final void Function(String name, List<String> agentIds) onCreateGroup;

  const _NewConversationSheet({
    required this.onStartDm,
    required this.onCreateGroup,
  });

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  bool _isGroupMode = false;
  final Set<String> _selectedAgents = {};
  final TextEditingController _groupNameController = TextEditingController();

  // TODO: Load agents from SocialService
  final List<Map<String, String>> _availableAgents = [
    {'id': 'weather_agent', 'name': 'Weather Agent', 'emoji': ''},
    {'id': 'calendar_agent', 'name': 'Calendar Agent', 'emoji': ''},
    {'id': 'notes_agent', 'name': 'Notes Agent', 'emoji': ''},
    {'id': 'calculator_agent', 'name': 'Calculator Agent', 'emoji': ''},
    {'id': 'search_agent', 'name': 'Search Agent', 'emoji': ''},
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _isGroupMode ? 'Create Group' : 'Start Conversation',
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isGroupMode = !_isGroupMode;
                      _selectedAgents.clear();
                    });
                  },
                  child: Text(_isGroupMode ? 'DM Mode' : 'Group Mode'),
                ),
              ],
            ),
          ),
          if (_isGroupMode) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Group name',
                  hintStyle: const TextStyle(color: Color(0xFF757575)),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Color(0xFFEDEDED)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select agents:',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _availableAgents.length,
              itemBuilder: (context, index) {
                final agent = _availableAgents[index];
                final isSelected = _selectedAgents.contains(agent['id']);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4A4A4A),
                    child: Text(
                      agent['emoji'] ?? agent['name']![0],
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    agent['name']!,
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                  ),
                  trailing: _isGroupMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedAgents.add(agent['id']!);
                              } else {
                                _selectedAgents.remove(agent['id']);
                              }
                            });
                          },
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF757575),
                        ),
                  onTap: () {
                    if (_isGroupMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedAgents.remove(agent['id']);
                        } else {
                          _selectedAgents.add(agent['id']!);
                        }
                      });
                    } else {
                      widget.onStartDm(agent['id']!);
                    }
                  },
                );
              },
            ),
          ),
          if (_isGroupMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAgents.isNotEmpty &&
                          _groupNameController.text.isNotEmpty
                      ? () {
                          widget.onCreateGroup(
                            _groupNameController.text,
                            _selectedAgents.toList(),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4A4A),
                    foregroundColor: const Color(0xFFEDEDED),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Create Group'),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
