import 'package:flutter/material.dart';
import 'package:vos_app/core/models/notes_models.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const NoteCard({
    Key? key,
    required this.note,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onDelete,
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
    final preview = content.length > 200 ? '${content.substring(0, 200)}...' : content;

    return Card(
      color: _getNoteColor(),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and actions row
              Row(
                children: [
                  if (note.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.push_pin, size: 16, color: Colors.black54),
                    ),
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          onPin?.call();
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
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Unpin' : 'Pin'),
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

              // Content preview
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
