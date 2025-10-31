import 'package:flutter/material.dart';
import 'package:vos_app/core/models/notes_models.dart';

class CreateNoteDialog extends StatefulWidget {
  final Note? existingNote;
  final Function(CreateNoteRequest) onSave;

  const CreateNoteDialog({
    Key? key,
    this.existingNote,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final TextEditingController _folderController;

  String? _selectedColor;
  bool _isPinned = false;
  final List<String> _colors = ['red', 'blue', 'green', 'yellow', 'orange', 'purple'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.existingNote?.tags?.join(', ') ?? '',
    );
    _folderController = TextEditingController(text: widget.existingNote?.folder ?? '');
    _selectedColor = widget.existingNote?.color;
    _isPinned = widget.existingNote?.isPinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingNote == null ? 'Create Note' : 'Edit Note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'work, important, personal',
              ),
            ),
            const SizedBox(height: 16),

            // Folder
            TextField(
              controller: _folderController,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
                hintText: 'Work/Projects',
              ),
            ),
            const SizedBox(height: 16),

            // Color selection
            Row(
              children: [
                const Text('Color: '),
                const SizedBox(width: 8),
                ..._colors.map((color) => _buildColorOption(color)),
                if (_selectedColor != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _selectedColor = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Pin checkbox
            Row(
              children: [
                Checkbox(
                  value: _isPinned,
                  onChanged: (value) => setState(() => _isPinned = value ?? false),
                ),
                const Text('Pin this note'),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String color) {
    final isSelected = _selectedColor == color;
    Color colorValue;

    switch (color) {
      case 'red':
        colorValue = Colors.red;
        break;
      case 'blue':
        colorValue = Colors.blue;
        break;
      case 'green':
        colorValue = Colors.green;
        break;
      case 'yellow':
        colorValue = Colors.yellow;
        break;
      case 'orange':
        colorValue = Colors.orange;
        break;
      case 'purple':
        colorValue = Colors.purple;
        break;
      default:
        colorValue = Colors.grey;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: colorValue,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final request = CreateNoteRequest(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: tags.isEmpty ? null : tags,
      folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(),
      color: _selectedColor,
      isPinned: _isPinned,
      createdBy: 'user',  // This should come from auth
    );

    widget.onSave(request);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _folderController.dispose();
    super.dispose();
  }
}
