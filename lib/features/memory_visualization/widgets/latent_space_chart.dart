import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vos_app/core/models/memory_models.dart';

class LatentSpaceChart extends StatefulWidget {
  final List<VisualizationPoint> points;
  final Set<String> highlightedIds;
  final Function(VisualizationPoint) onPointTap;
  final bool is3D;

  const LatentSpaceChart({
    Key? key,
    required this.points,
    this.highlightedIds = const {},
    required this.onPointTap,
    this.is3D = false,
  }) : super(key: key);

  @override
  State<LatentSpaceChart> createState() => _LatentSpaceChartState();
}

class _LatentSpaceChartState extends State<LatentSpaceChart> {
  VisualizationPoint? _hoveredPoint;

  @override
  Widget build(BuildContext context) {
    if (widget.is3D) {
      // 3D view - show placeholder for now
      return _build3DPlaceholder();
    }

    return _build2DScatterChart();
  }

  Widget _build2DScatterChart() {
    if (widget.points.isEmpty) {
      return const Center(
        child: Text(
          'No memories to visualize',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Calculate bounds
    double minX = widget.points.first.x;
    double maxX = widget.points.first.x;
    double minY = widget.points.first.y;
    double maxY = widget.points.first.y;

    for (final point in widget.points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    // Add padding
    final paddingX = (maxX - minX) * 0.1;
    final paddingY = (maxY - minY) * 0.1;
    minX -= paddingX;
    maxX += paddingX;
    minY -= paddingY;
    maxY += paddingY;

    return Stack(
      children: [
        ScatterChart(
          ScatterChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            scatterSpots: widget.points.map((point) {
              return ScatterSpot(
                point.x,
                point.y,
                dotPainter: FlDotCirclePainter(
                  color: _getColorForMemoryType(point.memoryType),
                  radius: _getRadiusForPoint(point),
                ),
              );
            }).toList(),
            scatterTouchData: ScatterTouchData(
              enabled: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipColor: (spot) => const Color(0xFF2d2d2d).withOpacity(0.95),
                getTooltipItems: (ScatterSpot spot) {
                  final point = _findPointAt(spot.x, spot.y);
                  if (point == null) return null;

                  return ScatterTooltipItem(
                    '${point.memoryType}\n${point.content.length > 100 ? point.content.substring(0, 100) + '...' : point.content}\n\nImportance: ${point.importance.toStringAsFixed(2)}\nAccess count: ${point.accessCount}',
                  );
                },
              ),
              handleBuiltInTouches: true,
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              horizontalInterval: (maxY - minY) / 5,
              verticalInterval: (maxX - minX) / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        ),
        // Legend
        Positioned(
          top: 10,
          right: 10,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final types = widget.points
        .map((p) => p.memoryType)
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d).withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Memory Types',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...types.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForMemoryType(type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _build3DPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_in_ar_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            '3D visualization',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForMemoryType(String type) {
    switch (type) {
      case 'user_preference':
        return const Color(0xFF00BCD4); // Cyan
      case 'user_fact':
        return const Color(0xFF4CAF50); // Green
      case 'conversation_context':
        return const Color(0xFFFF9800); // Orange
      case 'agent_procedure':
        return const Color(0xFF9C27B0); // Purple
      case 'knowledge':
        return const Color(0xFF2196F3); // Blue
      case 'event_pattern':
        return const Color(0xFFFFEB3B); // Yellow
      case 'error_handling':
        return const Color(0xFFF44336); // Red
      case 'proactive_action':
        return const Color(0xFF00E676); // Light Green
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  double _getRadiusForPoint(VisualizationPoint point) {
    final baseRadius = 6.0;
    final importanceMultiplier = point.importance * 1.5;
    final isHighlighted = widget.highlightedIds.contains(point.id);

    return baseRadius * importanceMultiplier * (isHighlighted ? 1.5 : 1.0);
  }

  VisualizationPoint? _findPointAt(double x, double y) {
    const tolerance = 0.01;
    for (final point in widget.points) {
      if ((point.x - x).abs() < tolerance && (point.y - y).abs() < tolerance) {
        return point;
      }
    }
    return null;
  }
}
