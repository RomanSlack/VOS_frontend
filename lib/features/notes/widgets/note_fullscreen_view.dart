import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/core/services/notes_service.dart';
import 'package:vos_app/core/di/injection.dart';

class NoteFullscreenView extends StatefulWidget {
  final Note note;
  final VoidCallback onBack;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final Function(UpdateNoteRequest)? onUpdate;

  const NoteFullscreenView({
    Key? key,
    required this.note,
    required this.onBack,
    this.onPin,
    this.onArchive,
    this.onDelete,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<NoteFullscreenView> createState() => _NoteFullscreenViewState();
}

class _NoteFullscreenViewState extends State<NoteFullscreenView> {
  bool _isEditMode = false;
  bool _isLoadingContent = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late TextEditingController _folderController;
  String? _selectedColor;
  String _fullContent = '';
  late final NotesService _notesService;

  @override
  void initState() {
    super.initState();
    _notesService = getIt<NotesService>();
    final initialContent = widget.note.content ?? widget.note.contentPreview ?? '';
    _fullContent = initialContent;
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: initialContent);
    _tagsController = TextEditingController(
      text: widget.note.tags?.join(', ') ?? '',
    );
    _folderController = TextEditingController(text: widget.note.folder ?? '');
    _selectedColor = widget.note.color;

    // Always load full content from server to ensure we have the complete note
    _loadFullContent();
  }

  Future<void> _loadFullContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final response = await _notesService.toolHelper.getNote(
        noteId: widget.note.id,
        createdBy: widget.note.createdBy,
      );

      print('Get note response status: ${response.status}');
      print('Get note response result: ${response.result}');

      if (response.status == 'success' && response.result != null) {
        // The result might be the note directly or wrapped in a 'note' field
        dynamic noteData = response.result!['note'] ?? response.result;

        if (noteData != null) {
          final note = Note.fromJson(noteData is Map<String, dynamic> ? noteData : noteData as Map<String, dynamic>);
          final fullContent = note.content ?? note.contentPreview ?? '';

          print('Loaded full content length: ${fullContent.length}');
          print('Content preview: ${fullContent.substring(0, fullContent.length > 100 ? 100 : fullContent.length)}');

          setState(() {
            _fullContent = fullContent;
            _contentController.text = fullContent;
            _isLoadingContent = false;
          });
          return;
        }
      }

      print('Failed to load full content - using existing content');
    } catch (e, stackTrace) {
      print('Error loading full content: $e');
      print('Stack trace: $stackTrace');
    }

    setState(() {
      _isLoadingContent = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Color _getNoteColor() {
    switch (_selectedColor?.toLowerCase() ?? widget.note.color?.toLowerCase()) {
      case 'red':
        return const Color(0xFF2A2121); // Dark red tint
      case 'blue':
        return const Color(0xFF212329); // Dark blue tint
      case 'green':
        return const Color(0xFF212721); // Dark green tint
      case 'yellow':
        return const Color(0xFF2A2821); // Dark yellow tint
      case 'orange':
        return const Color(0xFF2A2421); // Dark orange tint
      case 'purple':
        return const Color(0xFF262229); // Dark purple tint
      default:
        return const Color(0xFF212121); // Default dark gray
    }
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      // Save changes
      _saveChanges();
    } else {
      // Entering edit mode
      setState(() {
        _isEditMode = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final request = UpdateNoteRequest(
      noteId: widget.note.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: tags.isEmpty ? null : tags,
      folder: _folderController.text.trim().isEmpty ? null : _folderController.text.trim(),
      color: _selectedColor,
      isPinned: widget.note.isPinned,
      createdBy: widget.note.createdBy,
    );

    // Call the update callback
    widget.onUpdate?.call(request);

    // Update local state immediately for instant feedback
    setState(() {
      _fullContent = _contentController.text.trim();
      _isEditMode = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getNoteColor(),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Content
          Expanded(
            child: _isEditMode ? _buildEditMode() : _buildViewMode(),
          ),
        ],
      ),
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
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFEDEDED)),
            onPressed: widget.onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              widget.note.isPinned ? 'Pinned Note' : 'Note',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEDEDED),
              ),
            ),
          ),
          // Edit/Save button
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.save : Icons.edit_outlined,
              color: const Color(0xFFFF9800),
            ),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Save' : 'Edit',
          ),
          // Pin button
          IconButton(
            icon: Icon(
              widget.note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: const Color(0xFFEDEDED),
            ),
            onPressed: widget.onPin,
            tooltip: widget.note.isPinned ? 'Unpin' : 'Pin',
          ),
          // Archive button
          IconButton(
            icon: Icon(
              widget.note.isArchived ? Icons.unarchive : Icons.archive_outlined,
              color: const Color(0xFFEDEDED),
            ),
            onPressed: widget.onArchive,
            tooltip: widget.note.isArchived ? 'Unarchive' : 'Archive',
          ),
          // More menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFEDEDED)),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyContent();
                  break;
                case 'delete':
                  widget.onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy content'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading indicator
          if (_isLoadingContent) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
          ],
          // Title
          Text(
            widget.note.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEDEDED),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (widget.note.folder != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF757575)),
                    const SizedBox(width: 4),
                    Text(
                      widget.note.folder!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
              if (widget.note.hasGcsContent == true) ...[
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud, size: 16, color: Color(0xFF757575)),
                    SizedBox(width: 4),
                    Text(
                      'Cloud',
                      style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
              if (widget.note.createdAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF757575)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.note.createdAt!),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              if (widget.note.updatedAt != null && widget.note.updatedAt != widget.note.createdAt)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.update, size: 16, color: Color(0xFF757575)),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_formatDate(widget.note.updatedAt!)}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                    ),
                  ],
                ),
            ],
          ),

          // Tags
          if (widget.note.tags != null && widget.note.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.note.tags!
                  .map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEDEDED),
                        ),
                        backgroundColor: const Color(0xFF424242),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),

          // Content
          if (!_isLoadingContent)
            SelectableText(
              _fullContent,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFFEDEDED),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    final List<String> colors = ['red', 'blue', 'green', 'yellow', 'orange', 'purple'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEDEDED),
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(color: const Color(0xFF757575).withOpacity(0.7)),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Folder
          TextField(
            controller: _folderController,
            style: const TextStyle(color: Color(0xFFEDEDED)),
            decoration: InputDecoration(
              labelText: 'Folder',
              labelStyle: const TextStyle(color: Color(0xFF757575)),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              prefixIcon: const Icon(Icons.folder_outlined, color: Color(0xFF757575)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tags
          TextField(
            controller: _tagsController,
            style: const TextStyle(color: Color(0xFFEDEDED)),
            decoration: InputDecoration(
              labelText: 'Tags (comma separated)',
              labelStyle: const TextStyle(color: Color(0xFF757575)),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              hintText: 'work, important, personal',
              hintStyle: TextStyle(color: const Color(0xFF757575).withOpacity(0.7)),
              prefixIcon: const Icon(Icons.label_outlined, color: Color(0xFF757575)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Color selection
          Row(
            children: [
              const Text(
                'Color: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEDEDED),
                ),
              ),
              const SizedBox(width: 8),
              ...colors.map((color) => _buildColorOption(color)),
              if (_selectedColor != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF757575)),
                  onPressed: () => setState(() => _selectedColor = null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),

          // Content
          TextField(
            controller: _contentController,
            maxLines: 20,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFFEDEDED),
            ),
            decoration: InputDecoration(
              hintText: 'Start typing your note content...',
              hintStyle: TextStyle(color: const Color(0xFF757575).withOpacity(0.7)),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              alignLabelWithHint: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
            ),
          ),
        ],
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

  void _copyContent() {
    final content = widget.note.content ?? widget.note.contentPreview ?? '';
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
