import 'package:flutter/material.dart';
import 'package:vos_app/core/models/notes_models.dart';

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

  @override
  void initState() {
    super.initState();
    _position = widget.position;
  }

  Color _getNoteColor() {
    switch (widget.note.color?.toLowerCase()) {
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
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
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
          width: 240,
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 400,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        widget.note.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Delete button
                    GestureDetector(
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
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.note.content ?? widget.note.contentPreview ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF212121),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              // Pin indicator at bottom
              if (widget.note.isPinned)
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
        ),
      ),
    );
  }
}
