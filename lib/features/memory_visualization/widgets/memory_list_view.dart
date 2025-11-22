import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vos_app/core/models/memory_models.dart';
import 'package:timeago/timeago.dart' as timeago;

class MemoryListView extends StatefulWidget {
  final List<VisualizationPoint> memories;
  final Set<String> highlightedIds;
  final Function(VisualizationPoint) onMemoryTap;
  final Function(String) onSearch;

  const MemoryListView({
    Key? key,
    required this.memories,
    this.highlightedIds = const {},
    required this.onMemoryTap,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<MemoryListView> createState() => _MemoryListViewState();
}

class _MemoryListViewState extends State<MemoryListView> {
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _scrollController = ItemScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search memories...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearch('');
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF303030),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              widget.onSearch(value);
              setState(() {});
            },
          ),
        ),
        // Memory count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '${widget.memories.length} memories',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              if (widget.highlightedIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${widget.highlightedIds.length} highlighted)',
                  style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Memory list
        Expanded(
          child: widget.memories.isEmpty
              ? const Center(
                  child: Text(
                    'No memories to display',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ScrollablePositionedList.builder(
                  itemCount: widget.memories.length,
                  itemScrollController: _scrollController,
                  itemBuilder: (context, index) {
                    final memory = widget.memories[index];
                    final isHighlighted = widget.highlightedIds.contains(memory.id);

                    return _MemoryCard(
                      memory: memory,
                      isHighlighted: isHighlighted,
                      onTap: () => widget.onMemoryTap(memory),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final VisualizationPoint memory;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _MemoryCard({
    Key? key,
    required this.memory,
    required this.isHighlighted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF00BCD4)
              : Colors.white.withOpacity(0.1),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Memory type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorForMemoryType(memory.memoryType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      memory.memoryType.replaceAll('_', ' '),
                      style: TextStyle(
                        color: _getColorForMemoryType(memory.memoryType),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Importance indicator
                  _buildImportanceBar(memory.importance),
                ],
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                memory.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Tags
              if (memory.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memory.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              // Footer metadata
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    memory.createdAt != null
                        ? timeago.format(DateTime.parse(memory.createdAt!))
                        : 'Unknown',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${memory.accessCount}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.psychology_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(memory.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportanceBar(double importance) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < (importance * 5).round();
        return Container(
          width: 8,
          height: 16,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: isFilled
                ? const Color(0xFFFFEB3B)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getColorForMemoryType(String type) {
    switch (type) {
      case 'user_preference':
        return const Color(0xFF00BCD4);
      case 'user_fact':
        return const Color(0xFF4CAF50);
      case 'conversation_context':
        return const Color(0xFFFF9800);
      case 'agent_procedure':
        return const Color(0xFF9C27B0);
      case 'knowledge':
        return const Color(0xFF2196F3);
      case 'event_pattern':
        return const Color(0xFFFFEB3B);
      case 'error_handling':
        return const Color(0xFFF44336);
      case 'proactive_action':
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF757575);
    }
  }
}
