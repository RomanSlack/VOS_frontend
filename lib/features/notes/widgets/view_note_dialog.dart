import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vos_app/core/models/notes_models.dart';

class ViewNoteDialog extends StatelessWidget {
  final Note note;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const ViewNoteDialog({
    Key? key,
    required this.note,
    this.onEdit,
    this.onPin,
    this.onArchive,
    this.onDelete,
  }) : super(key: key);

  Color _getNoteColor() {
    switch (note.color?.toLowerCase()) {
      case 'red':
        return Colors.red.shade50;
      case 'blue':
        return Colors.blue.shade50;
      case 'green':
        return Colors.green.shade50;
      case 'yellow':
        return Colors.yellow.shade50;
      case 'orange':
        return Colors.orange.shade50;
      case 'purple':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = note.content ?? '';

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: _getNoteColor(),
        appBar: AppBar(
          backgroundColor: _getNoteColor(),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            note.isPinned ? 'Pinned Note' : 'Note',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
              onPressed: () {
                Navigator.pop(context);
                onEdit?.call();
              },
              tooltip: 'Edit',
            ),
            // Pin button
            IconButton(
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: Colors.black87,
              ),
              onPressed: () {
                onPin?.call();
              },
              tooltip: note.isPinned ? 'Unpin' : 'Pin',
            ),
            // Archive button
            IconButton(
              icon: Icon(
                note.isArchived ? Icons.unarchive : Icons.archive_outlined,
                color: Colors.black87,
              ),
              onPressed: () {
                Navigator.pop(context);
                onArchive?.call();
              },
              tooltip: note.isArchived ? 'Unarchive' : 'Archive',
            ),
            // More menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                switch (value) {
                  case 'copy':
                    _copyContent(context);
                    break;
                  case 'delete':
                    Navigator.pop(context);
                    onDelete?.call();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Metadata row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (note.folder != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          note.folder!,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                  if (note.hasGcsContent == true) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Cloud',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                  if (note.createdAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(note.createdAt!),
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  if (note.updatedAt != null && note.updatedAt != note.createdAt)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Updated ${_formatDate(note.updatedAt!)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                ],
              ),

              // Tags
              if (note.tags != null && note.tags!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: note.tags!
                      .map((tag) => Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.7),
                            side: BorderSide(color: Colors.grey.shade300),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 24),

              // Content
              SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyContent(BuildContext context) {
    final content = note.content ?? '';
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Content copied to clipboard'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
