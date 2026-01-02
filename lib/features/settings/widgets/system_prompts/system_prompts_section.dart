import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_bloc.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_event.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_state.dart';
import 'prompt_card.dart';
import 'section_card.dart';
import 'prompt_editor_dialog.dart';
import 'section_editor_dialog.dart';
import 'version_history_dialog.dart';
import 'prompt_preview_dialog.dart';

class SystemPromptsSection extends StatelessWidget {
  const SystemPromptsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SystemPromptsBloc>()..add(const LoadSections()),
      child: const _SystemPromptsSectionContent(),
    );
  }
}

class _SystemPromptsSectionContent extends StatelessWidget {
  const _SystemPromptsSectionContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemPromptsBloc, SystemPromptsState>(
      listener: (context, state) {
        if (state is SystemPromptsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  context.read<SystemPromptsBloc>().add(const ClearError());
                },
              ),
            ),
          );
        } else if (state is OperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is VersionsLoaded) {
          _showVersionsDialog(context, state);
        } else if (state is PreviewLoaded) {
          _showPreviewDialog(context, state);
        }
      },
      builder: (context, state) {
        if (state is SystemPromptsLoading) {
          return const _LoadingCard();
        }

        SystemPromptsLoaded? loaded;
        if (state is SystemPromptsLoaded) {
          loaded = state;
        } else if (state is OperationSuccess) {
          loaded = state.updatedState;
        } else if (state is SystemPromptsError && state.previousState != null) {
          loaded = state.previousState;
        }

        if (loaded == null) {
          return const _ErrorCard(message: 'Failed to load system prompts');
        }

        return _LoadedContent(state: loaded);
      },
    );
  }

  void _showVersionsDialog(BuildContext context, VersionsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SystemPromptsBloc>(),
        child: VersionHistoryDialog(
          versions: state.versions,
          promptId: state.promptId,
        ),
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, PreviewLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => PromptPreviewDialog(preview: state.preview),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.read<SystemPromptsBloc>().add(const LoadSections());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  final SystemPromptsLoaded state;

  const _LoadedContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tabs
          _buildHeader(context),
          const Divider(color: AppColors.surfaceVariant, height: 1),

          // Content based on selected tab
          if (state.selectedTabIndex == 0)
            _PromptsTab(state: state)
          else
            _SectionsTab(state: state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Tab buttons
          _TabButton(
            label: 'Prompts',
            isSelected: state.selectedTabIndex == 0,
            onTap: () {
              context.read<SystemPromptsBloc>().add(const SwitchTab(0));
            },
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Sections',
            isSelected: state.selectedTabIndex == 1,
            onTap: () {
              context.read<SystemPromptsBloc>().add(const SwitchTab(1));
            },
          ),
          const Spacer(),

          // Agent selector (only for prompts tab)
          if (state.selectedTabIndex == 0) _AgentDropdown(state: state),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AgentDropdown extends StatelessWidget {
  final SystemPromptsLoaded state;

  const _AgentDropdown({required this.state});

  @override
  Widget build(BuildContext context) {
    final selectedAgent = AgentInfo.byId(state.selectedAgentId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedAgentId,
          dropdownColor: AppColors.surfaceDark,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: AgentInfo.allAgents.map((agent) {
            return DropdownMenuItem(
              value: agent.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAgentIcon(agent.icon),
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    agent.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (agentId) {
            if (agentId != null) {
              context.read<SystemPromptsBloc>().add(SelectAgent(agentId));
            }
          },
        ),
      ),
    );
  }

  IconData _getAgentIcon(String iconName) {
    switch (iconName) {
      case 'hub':
        return Icons.hub;
      case 'language':
        return Icons.language;
      case 'cloud':
        return Icons.cloud;
      case 'search':
        return Icons.search;
      case 'note':
        return Icons.note;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'calculate':
        return Icons.calculate;
      default:
        return Icons.smart_toy;
    }
  }
}

class _PromptsTab extends StatelessWidget {
  final SystemPromptsLoaded state;

  const _PromptsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.prompts.isEmpty)
            const _EmptyState(
              icon: Icons.description_outlined,
              message: 'No prompts configured for this agent',
            )
          else
            ...state.prompts.map((prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PromptCard(
                    prompt: prompt,
                    onEdit: () => _showEditDialog(context, prompt),
                    onActivate: prompt.isActive
                        ? null
                        : () {
                            context
                                .read<SystemPromptsBloc>()
                                .add(ActivatePrompt(prompt.id));
                          },
                    onVersions: () {
                      context
                          .read<SystemPromptsBloc>()
                          .add(LoadVersions(prompt.id));
                    },
                    onPreview: () {
                      context
                          .read<SystemPromptsBloc>()
                          .add(LoadPreview(prompt.id));
                    },
                  ),
                )),
          const SizedBox(height: 8),
          _AddButton(
            label: 'New Prompt',
            onTap: () => _showCreateDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SystemPromptsBloc>(),
        child: PromptEditorDialog(
          agentId: state.selectedAgentId,
          sections: state.sections,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, SystemPrompt prompt) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SystemPromptsBloc>(),
        child: PromptEditorDialog(
          agentId: state.selectedAgentId,
          sections: state.sections,
          existingPrompt: prompt,
        ),
      ),
    );
  }
}

class _SectionsTab extends StatelessWidget {
  final SystemPromptsLoaded state;

  const _SectionsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.sections.isEmpty)
            const _EmptyState(
              icon: Icons.folder_outlined,
              message: 'No sections created yet',
            )
          else
            ...state.sortedSections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    section: section,
                    onEdit: () => _showEditDialog(context, section),
                    onDelete: () => _confirmDelete(context, section),
                  ),
                )),
          const SizedBox(height: 8),
          _AddButton(
            label: 'New Section',
            onTap: () => _showCreateDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SystemPromptsBloc>(),
        child: const SectionEditorDialog(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, PromptSection section) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SystemPromptsBloc>(),
        child: SectionEditorDialog(existingSection: section),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PromptSection section) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Delete Section',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${section.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<SystemPromptsBloc>()
                  .add(DeleteSection(section.sectionId));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
