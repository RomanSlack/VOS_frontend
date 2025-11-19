import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/core/services/notes_service.dart';
import 'package:vos_app/core/di/injection.dart';

class NoteFullscreenView extends StatefulWidget {
  final Note note;
  final VoidCallback onBack;
  final VoidCallback? onStar;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final Function(UpdateNoteRequest)? onUpdate;

  const NoteFullscreenView({
    Key? key,
    required this.note,
    required this.onBack,
    this.onStar,
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
              widget.note.isPinned ? 'Starred Note' : 'Note',
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
          // Star button
          IconButton(
            icon: Icon(
              widget.note.isPinned ? Icons.star : Icons.star_border,
              color: widget.note.isPinned ? Colors.amber : const Color(0xFFEDEDED),
            ),
            onPressed: widget.onStar,
            tooltip: widget.note.isPinned ? 'Unstar' : 'Star',
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

          // Content with markdown rendering
          if (!_isLoadingContent)
            Markdown(
              data: _fullContent,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFFEDEDED)),
                h1: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                h2: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                h3: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                h4: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                h5: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                h6: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEDEDED)),
                code: const TextStyle(backgroundColor: Color(0xFF424242), color: Color(0xFFFF9800), fontSize: 14),
                blockquote: const TextStyle(color: Color(0xFF999999)),
                listBullet: const TextStyle(color: Color(0xFFEDEDED)),
                a: const TextStyle(color: Color(0xFF64B5F6), decoration: TextDecoration.underline),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined, size: 18, color: Color(0xFF757575)),
                    const SizedBox(width: 8),
                    const Text(
                      'Color Theme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEDEDED),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedColor != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedColor = null),
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFF757575)),
                        label: const Text(
                          'Reset',
                          style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => _buildColorOption(color)).toList(),
                ),
              ],
            ),
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

    // Use darker, more muted colors that match the theme
    switch (color) {
      case 'red':
        colorValue = const Color(0xFFEF5350); // Softer red
        break;
      case 'blue':
        colorValue = const Color(0xFF42A5F5); // Softer blue
        break;
      case 'green':
        colorValue = const Color(0xFF66BB6A); // Softer green
        break;
      case 'yellow':
        colorValue = const Color(0xFFFFEE58); // Softer yellow
        break;
      case 'orange':
        colorValue = const Color(0xFFFF9800); // Match site accent
        break;
      case 'purple':
        colorValue = const Color(0xFFAB47BC); // Softer purple
        break;
      default:
        colorValue = const Color(0xFF757575);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorValue : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorValue : colorValue.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorValue,
              shape: BoxShape.circle,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: colorValue.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Color(0xFF212121), size: 16)
                : null,
          ),
        ),
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
