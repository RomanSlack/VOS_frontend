import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vos_app/core/models/document_models.dart';
import 'package:vos_app/core/services/document_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/presentation/widgets/document_viewer.dart';

/// Panel/sidebar for displaying and managing documents
class DocumentsPanel extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const DocumentsPanel({
    super.key,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  State<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends State<DocumentsPanel> {
  late final DocumentService _documentService;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;
  String? _selectedAgent;
  StreamSubscription? _newDocumentSubscription;

  @override
  void initState() {
    super.initState();
    _documentService = getIt<DocumentService>();
    _documentService.loadDocuments(refresh: true);

    // Listen for new documents
    _newDocumentSubscription = _documentService.newDocumentStream.listen((doc) {
      // Show a notification for new documents
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New document: ${doc.title}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _openDocument(doc),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newDocumentSubscription?.cancel();
    super.dispose();
  }

  void _openDocument(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewer(document: document),
      ),
    );
  }

  void _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Delete Document?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${document.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _documentService.deleteDocument(document.documentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Document deleted' : 'Failed to delete document',
            ),
          ),
        );
      }
    }
  }

  List<Document> _getFilteredDocuments() {
    var documents = _documentService.documents;

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      documents = documents.where((doc) {
        return doc.title.toLowerCase().contains(searchQuery) ||
            (doc.content?.toLowerCase().contains(searchQuery) ?? false) ||
            (doc.tags?.any((tag) => tag.toLowerCase().contains(searchQuery)) ?? false);
      }).toList();
    }

    // Apply tag filter
    if (_selectedTag != null) {
      documents = documents.where((doc) {
        return doc.tags?.contains(_selectedTag) ?? false;
      }).toList();
    }

    // Apply agent filter
    if (_selectedAgent != null) {
      documents = documents.where((doc) {
        return doc.sourceAgentId == _selectedAgent;
      }).toList();
    }

    return documents;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _buildCollapsedPanel();
    }

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Search bar
          _buildSearchBar(),

          // Filters
          _buildFilters(),

          // Document list
          Expanded(
            child: _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPanel() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        width: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border(
            left: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.description_outlined,
              color: Color(0xFF00BCD4),
              size: 24,
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: _documentService,
              builder: (context, _) {
                final count = _documentService.documentCount;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF00BCD4),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Documents',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _documentService,
            builder: (context, _) {
              return Text(
                '${_documentService.documentCount}',
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              );
            },
          ),
          if (widget.onToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white54),
              onPressed: widget.onToggle,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search documents...',
          hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF757575), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF757575), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFilters() {
    return ListenableBuilder(
      listenable: _documentService,
      builder: (context, _) {
        final tags = _documentService.allTags.toList()..sort();
        final agents = _documentService.allAgentIds.toList()..sort();

        if (tags.isEmpty && agents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Clear filters button
              if (_selectedTag != null || _selectedAgent != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Clear'),
                    selected: false,
                    onSelected: (_) {
                      setState(() {
                        _selectedTag = null;
                        _selectedAgent = null;
                      });
                    },
                    backgroundColor: const Color(0xFF2D2D2D),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),

              // Tag filters
              ...tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTag = selected ? tag : null;
                        });
                      },
                      selectedColor: const Color(0xFF00BCD4).withOpacity(0.3),
                      backgroundColor: const Color(0xFF2D2D2D),
                      labelStyle: TextStyle(
                        color: _selectedTag == tag ? const Color(0xFF00BCD4) : Colors.white70,
                        fontSize: 12,
                      ),
                      checkmarkColor: const Color(0xFF00BCD4),
                    ),
                  )),

              // Agent filters
              ...agents.map((agent) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_formatAgentName(agent)),
                      selected: _selectedAgent == agent,
                      onSelected: (selected) {
                        setState(() {
                          _selectedAgent = selected ? agent : null;
                        });
                      },
                      selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
                      backgroundColor: const Color(0xFF2D2D2D),
                      labelStyle: TextStyle(
                        color: _selectedAgent == agent ? const Color(0xFF4CAF50) : Colors.white70,
                        fontSize: 12,
                      ),
                      checkmarkColor: const Color(0xFF4CAF50),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    return ListenableBuilder(
      listenable: _documentService,
      builder: (context, _) {
        if (_documentService.isLoading && _documentService.documents.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
            ),
          );
        }

        if (_documentService.error != null && _documentService.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load documents',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _documentService.loadDocuments(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final documents = _getFilteredDocuments();

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty || _selectedTag != null || _selectedAgent != null
                      ? 'No documents match your filters'
                      : 'No documents yet',
                  style: const TextStyle(color: Color(0xFF757575)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _documentService.loadDocuments(refresh: true),
          color: const Color(0xFF00BCD4),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: documents.length + (_documentService.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= documents.length) {
                // Load more indicator
                _documentService.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                      ),
                    ),
                  ),
                );
              }

              final document = documents[index];
              return _DocumentListItem(
                document: document,
                onTap: () => _openDocument(document),
                onDelete: () => _deleteDocument(document),
              );
            },
          ),
        );
      },
    );
  }

  String _formatAgentName(String agentId) {
    return agentId
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Individual document list item
class _DocumentListItem extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentListItem({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(
                  _getDocumentIcon(),
                  color: _getSourceColor(),
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
                // Context menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                  padding: EdgeInsets.zero,
                  color: const Color(0xFF2D2D2D),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    } else if (value == 'copy_id') {
                      Clipboard.setData(ClipboardData(text: document.documentId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document ID copied')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy_id',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Copy ID', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Preview
            if (document.contentPreview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  document.contentPreview,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Metadata row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  // Source agent
                  if (document.sourceAgentId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSourceColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.sourceAgentDisplayName,
                        style: TextStyle(
                          color: _getSourceColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Tags
                  if (document.tags != null && document.tags!.isNotEmpty)
                    ...document.tags!.take(2).map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF424242),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )),

                  const Spacer(),

                  // Timestamp
                  Text(
                    _formatTimestamp(document.createdAtDateTime),
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
    );
  }

  IconData _getDocumentIcon() {
    final sourceType = document.sourceType?.toLowerCase() ?? '';
    if (sourceType.contains('search')) return Icons.search;
    if (sourceType.contains('tool')) return Icons.build;
    if (sourceType.contains('code')) return Icons.code;
    return Icons.description_outlined;
  }

  Color _getSourceColor() {
    final agentId = document.sourceAgentId?.toLowerCase() ?? '';
    if (agentId.contains('search')) return const Color(0xFF00BCD4);
    if (agentId.contains('code')) return const Color(0xFFFF9800);
    if (agentId.contains('research')) return const Color(0xFF4CAF50);
    return const Color(0xFF9E9E9E);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}';
  }
}
