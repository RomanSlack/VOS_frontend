import 'package:flutter/material.dart';
import 'package:vos_app/core/models/document_models.dart';
import 'package:vos_app/presentation/widgets/document_viewer.dart';

/// Widget to display documents inline in a chat message
class MessageDocuments extends StatelessWidget {
  final List<Document> documents;
  final bool isUserMessage;

  const MessageDocuments({
    super.key,
    required this.documents,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: documents.map((doc) => _DocumentCard(document: doc)).toList(),
      ),
    );
  }
}

/// Individual document card for inline display
class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  void _openDocument(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewer(document: document),
      ),
    );
  }

  IconData _getSourceIcon() {
    final agentId = document.sourceAgentId?.toLowerCase() ?? '';
    if (agentId.contains('search')) return Icons.search;
    if (agentId.contains('code')) return Icons.code;
    if (agentId.contains('research')) return Icons.science;
    if (agentId.contains('weather')) return Icons.cloud;
    if (agentId.contains('calendar')) return Icons.calendar_today;
    return Icons.description;
  }

  Color _getSourceColor() {
    final agentId = document.sourceAgentId?.toLowerCase() ?? '';
    if (agentId.contains('search')) return const Color(0xFF00BCD4);
    if (agentId.contains('code')) return const Color(0xFFFF9800);
    if (agentId.contains('research')) return const Color(0xFF4CAF50);
    if (agentId.contains('weather')) return const Color(0xFF2196F3);
    if (agentId.contains('calendar')) return const Color(0xFFE91E63);
    return const Color(0xFF00BCD4);
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = _getSourceColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDocument(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sourceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sourceColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Document icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: sourceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getSourceIcon(),
                    size: 16,
                    color: sourceColor,
                  ),
                ),
                const SizedBox(width: 10),
                // Document info
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          color: sourceColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (document.contentPreview.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            document.contentPreview,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (document.sourceAgentId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 10,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                document.sourceAgentDisplayName,
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Open indicator
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: sourceColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
