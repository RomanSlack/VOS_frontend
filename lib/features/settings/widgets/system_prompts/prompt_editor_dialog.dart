import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_bloc.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_event.dart';

class PromptEditorDialog extends StatefulWidget {
  final String agentId;
  final List<PromptSection> sections;
  final SystemPrompt? existingPrompt;

  const PromptEditorDialog({
    super.key,
    required this.agentId,
    required this.sections,
    this.existingPrompt,
  });

  @override
  State<PromptEditorDialog> createState() => _PromptEditorDialogState();
}

class _PromptEditorDialogState extends State<PromptEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late List<String> _selectedSectionIds;
  late String _toolsPosition;
  bool _isActive = false;

  bool get isEditing => widget.existingPrompt != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPrompt?.name ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingPrompt?.content ?? '',
    );
    _selectedSectionIds =
        List.from(widget.existingPrompt?.sectionIds ?? []);
    _toolsPosition = widget.existingPrompt?.toolsPosition ?? 'end';
    _isActive = widget.existingPrompt?.isActive ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildSectionSelector(),
                    const SizedBox(height: 16),
                    _buildToolsPositionSelector(),
                    const SizedBox(height: 16),
                    if (!isEditing) _buildActiveCheckbox(),
                    if (!isEditing) const SizedBox(height: 16),
                    _buildContentField(),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            isEditing ? 'Edit Prompt' : 'Create Prompt',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter prompt name',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Include Sections',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: widget.sections.isEmpty
              ? const Text(
                  'No sections available',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  children: widget.sections.map((section) {
                    final isSelected =
                        _selectedSectionIds.contains(section.sectionId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedSectionIds.add(section.sectionId);
                          } else {
                            _selectedSectionIds.remove(section.sectionId);
                          }
                        });
                      },
                      title: Text(
                        section.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        section.sectionId,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          section.sectionType,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildToolsPositionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tools Position',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPositionOption('start', 'Start'),
            const SizedBox(width: 12),
            _buildPositionOption('end', 'End'),
            const SizedBox(width: 12),
            _buildPositionOption('none', 'None'),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionOption(String value, String label) {
    final isSelected = _toolsPosition == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _toolsPosition = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        const Text(
          'Set as active prompt',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Main Content',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Enter main prompt content...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and content are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (isEditing) {
      context.read<SystemPromptsBloc>().add(UpdatePrompt(
            widget.existingPrompt!.id,
            SystemPromptUpdate(
              name: name,
              content: content,
              sectionIds: _selectedSectionIds,
              toolsPosition: _toolsPosition,
            ),
          ));
    } else {
      context.read<SystemPromptsBloc>().add(CreatePrompt(
            widget.agentId,
            SystemPromptCreate(
              name: name,
              content: content,
              sectionIds: _selectedSectionIds,
              toolsPosition: _toolsPosition,
              isActive: _isActive,
            ),
          ));
    }

    Navigator.pop(context);
  }
}
