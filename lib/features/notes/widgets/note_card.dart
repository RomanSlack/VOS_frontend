import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vos_app/core/models/notes_models.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onStar;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final Function(Note)? onDragToWorkspace;

  const NoteCard({
    Key? key,
    required this.note,
    this.onTap,
    this.onStar,
    this.onArchive,
    this.onDelete,
    this.onDragToWorkspace,
  }) : super(key: key);

  Color _getNoteColor() {
    switch (note.color?.toLowerCase()) {
      case 'red':
        return Colors.red.shade100;
      case 'blue':
        return Colors.blue.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'yellow':
        return Colors.yellow.shade100;
      case 'orange':
        return Colors.orange.shade100;
      case 'purple':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = note.content ?? note.contentPreview ?? '';
    // Dynamically determine preview length based on content
    int maxLines = 4;
    String preview;
    if (content.length <= 100) {
      preview = content;
      maxLines = 3;
    } else if (content.length <= 200) {
      preview = content;
      maxLines = 4;
    } else if (content.length <= 400) {
      preview = '${content.substring(0, 200)}...';
      maxLines = 5;
    } else {
      preview = '${content.substring(0, 150)}...';
      maxLines = 4;
    }

    return LongPressDraggable<Note>(
      data: note,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getNoteColor(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Icon(Icons.drag_indicator, color: Colors.black54, size: 20),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Card(
          color: _getNoteColor(),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
      onDragStarted: () {
        // Visual feedback
      },
      onDragEnd: (details) {
        if (details.wasAccepted) {
          // Successfully dropped on workspace
        }
      },
      child: Card(
        color: _getNoteColor(),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Title and actions row
              Row(
                children: [
                  if (note.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.star, size: 16, color: Colors.amber),
                    ),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    onSelected: (value) {
                      switch (value) {
                        case 'star':
                          onStar?.call();
                          break;
                        case 'archive':
                          onArchive?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'star',
                        child: Row(
                          children: [
                            Icon(note.isPinned ? Icons.star : Icons.star_border,
                                 color: note.isPinned ? Colors.amber : null),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Unstar' : 'Star'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(note.isArchived ? Icons.unarchive : Icons.archive),
                            const SizedBox(width: 8),
                            Text(note.isArchived ? 'Unarchive' : 'Archive'),
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

              // Content preview with markdown
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: maxLines * 20.0, // Approximate height per line
                  child: MarkdownBody(
                    data: preview,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                      h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      h5: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      h6: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                      code: TextStyle(backgroundColor: Colors.grey.shade300, fontSize: 13, color: Colors.black87),
                      blockquote: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                      listBullet: const TextStyle(color: Colors.black87),
                      tableBody: const TextStyle(color: Colors.black87),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                    shrinkWrap: true,
                  ),
                ),
              ],

              // Tags
              if (note.tags != null && note.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags!
                      .take(5)
                      .map((tag) => Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 11),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],

              // Footer with metadata
              const SizedBox(height: 12),
              Row(
                children: [
                  if (note.folder != null) ...[
                    Icon(Icons.folder_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      note.folder!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (note.hasGcsContent == true) ...[
                    Icon(Icons.cloud, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Cloud',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Spacer(),
                  if (note.updatedAt != null)
                    Text(
                      _formatDate(note.updatedAt!),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
