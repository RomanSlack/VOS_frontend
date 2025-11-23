import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/models/memory_models.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_bloc.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_event.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_state.dart';
import 'package:vos_app/features/memory_visualization/widgets/latent_space_chart.dart';
import 'package:vos_app/features/memory_visualization/widgets/memory_list_view.dart';
import 'package:vos_app/features/memory_visualization/widgets/filter_panel.dart';

class MemoryVizApp extends StatefulWidget {
  const MemoryVizApp({Key? key}) : super(key: key);

  @override
  State<MemoryVizApp> createState() => _MemoryVizAppState();
}

class _MemoryVizAppState extends State<MemoryVizApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MemoryVizBloc _memoryVizBloc;

  String _currentMethod = "umap";
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _memoryVizBloc = getIt<MemoryVizBloc>();

    // Load initial visualization
    _memoryVizBloc.add(const LoadVisualization());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _memoryVizBloc,
      child: Container(
        color: const Color(0xFF212121),
        child: Column(
          children: [
            // Toolbar
            _buildToolbar(),
            // Tab bar
            Container(
              color: const Color(0xFF303030),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00BCD4),
                labelColor: const Color(0xFF00BCD4),
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(icon: Icon(Icons.scatter_plot_outlined, size: 20), text: 'Latent Space'),
                  Tab(icon: Icon(Icons.list_alt, size: 20), text: 'List View'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: BlocBuilder<MemoryVizBloc, MemoryVizState>(
                builder: (context, state) {
                  if (state is MemoryVizLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading visualization...',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MemoryVizError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (state.details != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                state.details!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _memoryVizBloc.add(const RefreshVisualization());
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BCD4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is MemoryVizLoaded) {
                    return Row(
                      children: [
                        // Main content area
                        Expanded(
                          child: Column(
                            children: [
                              // Stats bar
                              if (state.statistics != null)
                                _buildStatsBar(state.statistics!),
                              // Chart/List
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // Latent Space View
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: LatentSpaceChart(
                                        points: state.points,
                                        highlightedIds: state.highlightedIds,
                                        onPointTap: _showMemoryDetail,
                                        is3D: state.dimensions == 3,
                                      ),
                                    ),
                                    // List View
                                    MemoryListView(
                                      memories: state.points,
                                      highlightedIds: state.highlightedIds,
                                      onMemoryTap: _showMemoryDetail,
                                      onSearch: (query) {
                                        if (query.isEmpty) {
                                          _memoryVizBloc.add(const ClearSearch());
                                        } else {
                                          _memoryVizBloc.add(SearchMemories(query));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Filter panel (sliding from right, overlay on mobile)
                        if (_showFilters)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              return Container(
                                width: isMobile ? constraints.maxWidth : 280,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF212121),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: FilterPanel(
                                selectedMemoryType: state.filters['memory_type'] as String?,
                                selectedScope: state.filters['scope'] as String?,
                                minImportance: state.filters['min_importance'] as double?,
                                onMemoryTypeChanged: (value) {
                                  _memoryVizBloc.add(UpdateFilters(memoryType: value));
                                },
                                onScopeChanged: (value) {
                                  _memoryVizBloc.add(UpdateFilters(scope: value));
                                },
                                onImportanceChanged: (value) {
                                  _memoryVizBloc.add(UpdateFilters(minImportance: value));
                                },
                              ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  }

                  return const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Method selector
          PopupMenuButton<String>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.scatter_plot_outlined, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    _currentMethod.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
            onSelected: (method) {
              setState(() {
                _currentMethod = method;
              });
              _memoryVizBloc.add(ChangeReductionMethod(method));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'umap',
                child: Row(
                  children: [
                    if (_currentMethod == 'umap')
                      const Icon(Icons.check, size: 16),
                    if (_currentMethod == 'umap')
                      const SizedBox(width: 8),
                    const Text('UMAP'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pca',
                child: Row(
                  children: [
                    if (_currentMethod == 'pca')
                      const Icon(Icons.check, size: 16),
                    if (_currentMethod == 'pca')
                      const SizedBox(width: 8),
                    const Text('PCA'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tsne',
                child: Row(
                  children: [
                    if (_currentMethod == 'tsne')
                      const Icon(Icons.check, size: 16),
                    if (_currentMethod == 'tsne')
                      const SizedBox(width: 8),
                    const Text('t-SNE'),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Filter toggle
          IconButton(
            icon: Icon(
              Icons.filter_list,
              size: 20,
              color: _showFilters ? const Color(0xFF00BCD4) : Colors.white.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filters',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // Refresh
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: Colors.white.withOpacity(0.7)),
            onPressed: () {
              _memoryVizBloc.add(const RefreshVisualization());
            },
            tooltip: 'Refresh',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(StatisticsResponse stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.memory_outlined,
            label: 'Total',
            value: stats.totalMemories.toString(),
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Icons.category_outlined,
            label: 'Types',
            value: stats.byType.length.toString(),
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Icons.label_outlined,
            label: 'Tags',
            value: stats.topTags.length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF00BCD4),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMemoryDetail(VisualizationPoint memory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF303030),
        title: Text(
          memory.memoryType.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                memory.content,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              _buildDetailRow('Importance', '${(memory.importance * 100).toStringAsFixed(0)}%'),
              _buildDetailRow('Confidence', '${(memory.confidence * 100).toStringAsFixed(0)}%'),
              _buildDetailRow('Access Count', memory.accessCount.toString()),
              if (memory.scope != null)
                _buildDetailRow('Scope', memory.scope!),
              if (memory.tags.isNotEmpty)
                _buildDetailRow('Tags', memory.tags.join(', ')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF00BCD4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
