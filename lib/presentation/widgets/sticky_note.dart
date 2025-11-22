import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/core/services/notes_service.dart';
import 'package:vos_app/core/di/injection.dart';

class StickyNote extends StatefulWidget {
  final Note note;
  final Offset position;
  final VoidCallback onDelete;
  final Function(Offset) onPositionChanged;

  const StickyNote({
    Key? key,
    required this.note,
    required this.position,
    required this.onDelete,
    required this.onPositionChanged,
  }) : super(key: key);

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote> {
  late Offset _position;
  bool _isDragging = false;
  late Note _currentNote;

  // Resizable size
  late double _width;
  late double _height;
  static const double _minWidth = 200;
  static const double _maxWidth = 500;
  static const double _minHeight = 150;
  static const double _maxHeight = 600;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _currentNote = widget.note;
    _width = 240;
    _height = 250;

    // Always fetch full note content (list only provides preview)
    _fetchFullContent();
  }

  Future<void> _fetchFullContent() async {
    try {
      final notesService = getIt<NotesService>();
      final response = await notesService.toolHelper.getNote(
        noteId: _currentNote.id,
      );

      if (response.status == 'success' && response.result != null && mounted) {
        final noteData = response.result!;
        final updatedNote = Note.fromJson(noteData);
        setState(() {
          _currentNote = updatedNote;
        });
      }
    } catch (e) {
      debugPrint('Error fetching full note content: $e');
    }
  }

  @override
  void didUpdateWidget(StickyNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update note when parent rebuilds with new data (from WebSocket)
    if (widget.note.id == _currentNote.id) {
      // Check if incoming note has full content (longer than current)
      final incomingContentLength = widget.note.content?.length ?? 0;
      final currentContentLength = _currentNote.content?.length ?? 0;

      // Only update content if incoming has MORE content (full content from WebSocket)
      // or if other metadata changed
      final hasMoreContent = incomingContentLength > currentContentLength;
      final metadataChanged = widget.note.title != _currentNote.title ||
          widget.note.color != _currentNote.color ||
          widget.note.isPinned != _currentNote.isPinned;

      if (hasMoreContent || metadataChanged) {
        setState(() {
          // If incoming has more content, use it entirely
          // Otherwise just update metadata but keep current content
          if (hasMoreContent) {
            _currentNote = widget.note;
          } else if (metadataChanged) {
            // Use copyWith to preserve full content while updating metadata
            _currentNote = widget.note.copyWith(
              content: _currentNote.content, // Keep full content
            );
          }
        });
      }
    }
  }

  Color _getNoteColor() {
    switch (_currentNote.color?.toLowerCase()) {
      case 'red':
        return const Color(0xFFFFCDD2);
      case 'blue':
        return const Color(0xFFBBDEFB);
      case 'green':
        return const Color(0xFFC8E6C9);
      case 'yellow':
        return const Color(0xFFFFF9C4);
      case 'orange':
        return const Color(0xFFFFE0B2);
      case 'purple':
        return const Color(0xFFE1BEE7);
      default:
        return const Color(0xFFFFF59D); // Classic sticky note yellow
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final screenSize = MediaQuery.of(context).size;
            final newX = _position.dx + details.delta.dx;
            final newY = _position.dy + details.delta.dy;

            // Constrain position to keep sticky note visible on screen
            // Allow some overflow but keep at least 50px visible
            _position = Offset(
              newX.clamp(-_width + 50, screenSize.width - 50),
              newY.clamp(0, screenSize.height - 50),
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
          widget.onPositionChanged(_position);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: _getNoteColor(),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDragging ? 0.4 : 0.25),
                blurRadius: _isDragging ? 24 : 16,
                spreadRadius: _isDragging ? 2 : 1,
                offset: Offset(0, _isDragging ? 8 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with drag handle and delete
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Drag handle
                        const Icon(
                          Icons.drag_indicator,
                          size: 16,
                          color: Color(0xFF424242),
                        ),
                        const SizedBox(width: 4),
                        // Title
                        Expanded(
                          child: Text(
                            _currentNote.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Delete button with pointer cursor
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content with markdown rendering and scrolling
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: MarkdownBody(
                          data: _currentNote.content ?? _currentNote.contentPreview ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF212121),
                            ),
                            h1: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            h2: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            h3: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            h4: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                            h5: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                            h6: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF212121),
                            ),
                            code: const TextStyle(
                              backgroundColor: Color(0xFFE0E0E0),
                              fontSize: 11,
                              color: Color(0xFF212121),
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            blockquote: const TextStyle(
                              color: Color(0xFF424242),
                              fontStyle: FontStyle.italic,
                            ),
                            listBullet: const TextStyle(color: Color(0xFF212121)),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF212121),
                            ),
                            a: const TextStyle(
                              color: Color(0xFF1565C0),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          softLineBreak: true,
                          selectable: true,
                        ),
                      ),
                    ),
                  ),
                  // Pin indicator at bottom
                  if (_currentNote.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 10, color: Color(0xFF757575)),
                          SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Resize handle at bottom-right corner
              Positioned(
                right: 0,
                bottom: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _width = (_width + details.delta.dx).clamp(_minWidth, _maxWidth);
                        _height = (_height + details.delta.dy).clamp(_minHeight, _maxHeight);
                      });
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.bottomRight,
                      child: Icon(
                        Icons.south_east,
                        size: 12,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
