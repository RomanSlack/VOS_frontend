import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_bloc.dart';
import 'package:vos_app/features/settings/bloc/system_prompts/system_prompts_event.dart';

class SectionEditorDialog extends StatefulWidget {
  final PromptSection? existingSection;

  const SectionEditorDialog({super.key, this.existingSection});

  @override
  State<SectionEditorDialog> createState() => _SectionEditorDialogState();
}

class _SectionEditorDialogState extends State<SectionEditorDialog> {
  late TextEditingController _sectionIdController;
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextEditingController _orderController;
  late String _sectionType;
  bool _isGlobal = false;

  bool get isEditing => widget.existingSection != null;

  @override
  void initState() {
    super.initState();
    _sectionIdController = TextEditingController(
      text: widget.existingSection?.sectionId ?? '',
    );
    _nameController = TextEditingController(
      text: widget.existingSection?.name ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingSection?.content ?? '',
    );
    _orderController = TextEditingController(
      text: (widget.existingSection?.displayOrder ?? 0).toString(),
    );
    _sectionType = widget.existingSection?.sectionType ?? 'custom';
    _isGlobal = widget.existingSection?.isGlobal ?? false;
  }

  @override
  void dispose() {
    _sectionIdController.dispose();
    _nameController.dispose();
    _contentController.dispose();
    _orderController.dispose();
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
                    if (!isEditing) _buildSectionIdField(),
                    if (!isEditing) const SizedBox(height: 16),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTypeSelector()),
                        const SizedBox(width: 16),
                        SizedBox(width: 100, child: _buildOrderField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlobalCheckbox(),
                    const SizedBox(height: 16),
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
            isEditing ? 'Edit Section' : 'Create Section',
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

  Widget _buildSectionIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Section ID',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Unique identifier used for referencing this section',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sectionIdController,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'my_section_id',
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
            hintText: 'Enter display name',
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sectionType,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
              items: SectionType.allTypes.map((type) {
                return DropdownMenuItem(
                  value: type.id,
                  child: Text(
                    type.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sectionType = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _orderController,
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
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

  Widget _buildGlobalCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isGlobal,
          onChanged: (value) {
            setState(() {
              _isGlobal = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Global section',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              Text(
                'Available to all agents',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Markdown is supported',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
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
            hintText: '## Section Title\n\nContent here...',
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
    final order = int.tryParse(_orderController.text.trim()) ?? 0;

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
      context.read<SystemPromptsBloc>().add(UpdateSection(
            widget.existingSection!.sectionId,
            PromptSectionUpdate(
              name: name,
              content: content,
              displayOrder: order,
              isGlobal: _isGlobal,
            ),
          ));
    } else {
      final sectionId = _sectionIdController.text.trim();
      if (sectionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section ID is required'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<SystemPromptsBloc>().add(CreateSection(
            PromptSectionCreate(
              sectionId: sectionId,
              sectionType: _sectionType,
              name: name,
              content: content,
              displayOrder: order,
              isGlobal: _isGlobal,
            ),
          ));
    }

    Navigator.pop(context);
  }
}
