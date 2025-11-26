import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vos_app/core/models/document_models.dart';

/// Full-screen document viewer with markdown rendering
class DocumentViewer extends StatelessWidget {
  final Document document;

  const DocumentViewer({
    super.key,
    required this.document,
  });

  void _copyContent(BuildContext context) {
    if (document.content != null) {
      Clipboard.setData(ClipboardData(text: document.content!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content copied to clipboard')),
      );
    }
  }

  void _copyDocumentId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: document.documentId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document ID copied to clipboard')),
    );
  }

  void _shareDocument(BuildContext context) {
    // For now, just copy the document ID as a reference
    final text = '''Document: ${document.title}
ID: ${document.documentId}
Source: ${document.sourceAgentDisplayName}
Created: ${document.createdAt}

${document.content ?? ''}''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document copied for sharing')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          document.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: () => _copyContent(context),
            tooltip: 'Copy content',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: () => _shareDocument(context),
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF2D2D2D),
            onSelected: (value) {
              if (value == 'copy_id') {
                _copyDocumentId(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_id',
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Copy ID', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Document metadata
          _buildMetadataBar(),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          // Source agent
          if (document.sourceAgentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSourceColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSourceIcon(),
                    size: 14,
                    color: _getSourceColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    document.sourceAgentDisplayName,
                    style: TextStyle(
                      color: _getSourceColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Source tool
          if (document.sourceTool != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                document.sourceTool!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Tags
          if (document.tags != null && document.tags!.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: document.tags!
                      .map((tag) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00BCD4).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Color(0xFF00BCD4),
                                fontSize: 11,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

          // Timestamp
          Text(
            _formatFullTimestamp(document.createdAtDateTime),
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (document.content == null || document.content!.isEmpty) {
      return const Center(
        child: Text(
          'No content available',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    // Check if content looks like markdown
    final isMarkdown = document.contentType == 'text/markdown' ||
        document.content!.contains('```') ||
        document.content!.contains('**') ||
        document.content!.contains('##') ||
        document.content!.contains('- ');

    if (isMarkdown) {
      return Markdown(
        data: document.content!,
        selectable: true,
        padding: const EdgeInsets.all(16),
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 14,
            height: 1.6,
          ),
          code: TextStyle(
            color: const Color(0xFF00BCD4),
            backgroundColor: Colors.black.withOpacity(0.3),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockPadding: const EdgeInsets.all(12),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: const TextStyle(
            color: Color(0xFF757575),
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF00BCD4).withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 16),
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h3: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          listBullet: const TextStyle(color: Color(0xFF00BCD4)),
          a: const TextStyle(
            color: Color(0xFF00BCD4),
            decoration: TextDecoration.underline,
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final uri = Uri.parse(href);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        },
      );
    }

    // Plain text
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        document.content!,
        style: const TextStyle(
          color: Color(0xFFEDEDED),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  IconData _getSourceIcon() {
    final agentId = document.sourceAgentId?.toLowerCase() ?? '';
    if (agentId.contains('search')) return Icons.search;
    if (agentId.contains('code')) return Icons.code;
    if (agentId.contains('research')) return Icons.science;
    return Icons.smart_toy;
  }

  Color _getSourceColor() {
    final agentId = document.sourceAgentId?.toLowerCase() ?? '';
    if (agentId.contains('search')) return const Color(0xFF00BCD4);
    if (agentId.contains('code')) return const Color(0xFFFF9800);
    if (agentId.contains('research')) return const Color(0xFF4CAF50);
    return const Color(0xFF9E9E9E);
  }

  String _formatFullTimestamp(DateTime timestamp) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');

    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} at $hour:$minute $ampm';
  }
}

/// Compact document preview card (for hover/tooltip)
class DocumentPreviewCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;

  const DocumentPreviewCard({
    super.key,
    required this.document,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                const Icon(
                  Icons.description,
                  color: Color(0xFF00BCD4),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Preview
            if (document.contentPreview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  document.contentPreview,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Source
            if (document.sourceAgentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'From: ${document.sourceAgentDisplayName}',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 11,
                  ),
                ),
              ),

            // Click hint
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Click to view full document',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
