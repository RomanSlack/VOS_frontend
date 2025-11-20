import 'package:flutter/material.dart';

class Workspace extends StatelessWidget {
  const Workspace({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size to ensure grid covers entire scaled area
    final screenSize = MediaQuery.of(context).size;

    return Positioned.fill(
      left: 112, // AppRail width (80) + margin (16) * 2
      right: 16, // Matching app rail margin
      // RepaintBoundary prevents grid from repainting when modals move
      child: RepaintBoundary(
        child: CustomPaint(
          painter: GridPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridColor = Color(0xFF2F2F2F);
    const strokeWidth = 0.5;
    const gridCount = 30; // About 30 grids wide as requested

    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final gridWidth = size.width / gridCount;
    final gridHeight = gridWidth; // Square grids
    final verticalLines = (size.height / gridHeight).ceil() + 1;

    // Create fade gradient for edges
    final fadeDistance = gridWidth * 3; // Fade over 3 grid units

    // Draw vertical lines
    for (int i = 0; i <= gridCount; i++) {
      final x = i * gridWidth;

      // Calculate fade factor for this line (distance from edges)
      final distanceFromLeft = x;
      final distanceFromRight = size.width - x;
      final horizontalFade = _calculateFade(
        distanceFromLeft,
        distanceFromRight,
        fadeDistance,
      );

      // Draw line segments with vertical fading
      _drawFadedVerticalLine(
        canvas,
        paint,
        x,
        size.height,
        gridHeight,
        fadeDistance,
        horizontalFade,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= verticalLines; i++) {
      final y = i * gridHeight;

      // Calculate fade factor for this line (distance from top/bottom)
      final distanceFromTop = y;
      final distanceFromBottom = size.height - y;
      final verticalFade = _calculateFade(
        distanceFromTop,
        distanceFromBottom,
        fadeDistance,
      );

      // Draw line segments with horizontal fading
      _drawFadedHorizontalLine(
        canvas,
        paint,
        y,
        size.width,
        gridWidth,
        fadeDistance,
        verticalFade,
      );
    }
  }

  void _drawFadedVerticalLine(
    Canvas canvas,
    Paint paint,
    double x,
    double height,
    double gridHeight,
    double fadeDistance,
    double horizontalFade,
  ) {
    final segments = (height / (gridHeight * 0.1)).ceil();

    for (int i = 0; i < segments; i++) {
      final segmentStart = i * (height / segments);
      final segmentEnd = (i + 1) * (height / segments);

      // Calculate vertical fade for this segment
      final distanceFromTop = segmentStart;
      final distanceFromBottom = height - segmentEnd;
      final verticalFade = _calculateFade(
        distanceFromTop,
        distanceFromBottom,
        fadeDistance,
      );

      // Combine horizontal and vertical fade
      final totalFade = horizontalFade * verticalFade;

      final segmentPaint = Paint()
        ..color = paint.color.withOpacity(totalFade)
        ..strokeWidth = paint.strokeWidth
        ..style = paint.style;

      canvas.drawLine(
        Offset(x, segmentStart),
        Offset(x, segmentEnd),
        segmentPaint,
      );
    }
  }

  void _drawFadedHorizontalLine(
    Canvas canvas,
    Paint paint,
    double y,
    double width,
    double gridWidth,
    double fadeDistance,
    double verticalFade,
  ) {
    final segments = (width / (gridWidth * 0.1)).ceil();

    for (int i = 0; i < segments; i++) {
      final segmentStart = i * (width / segments);
      final segmentEnd = (i + 1) * (width / segments);

      // Calculate horizontal fade for this segment
      final distanceFromLeft = segmentStart;
      final distanceFromRight = width - segmentEnd;
      final horizontalFade = _calculateFade(
        distanceFromLeft,
        distanceFromRight,
        fadeDistance,
      );

      // Combine horizontal and vertical fade
      final totalFade = horizontalFade * verticalFade;

      final segmentPaint = Paint()
        ..color = paint.color.withOpacity(totalFade)
        ..strokeWidth = paint.strokeWidth
        ..style = paint.style;

      canvas.drawLine(
        Offset(segmentStart, y),
        Offset(segmentEnd, y),
        segmentPaint,
      );
    }
  }

  double _calculateFade(double distanceFromEdge1, double distanceFromEdge2, double fadeDistance) {
    final minDistance = distanceFromEdge1 < distanceFromEdge2
        ? distanceFromEdge1
        : distanceFromEdge2;

    if (minDistance >= fadeDistance) {
      return 1.0; // Full opacity in center
    } else {
      return (minDistance / fadeDistance).clamp(0.0, 1.0); // Fade to edges
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}