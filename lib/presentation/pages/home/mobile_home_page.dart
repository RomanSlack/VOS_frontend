import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/app_icon.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/presentation/widgets/profile_dialog.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/sticky_notes_manager.dart';

/// Mobile-optimized VOS layout with:
/// - Horizontal scrolling app selector at top
/// - Split-view workspace (max 2 apps)
/// - Centered input bar at bottom
class MobileHomePage extends StatelessWidget {
  final VosModalManager modalManager;
  final StickyNotesManager stickyNotesManager;

  const MobileHomePage({
    super.key,
    required this.modalManager,
    required this.stickyNotesManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Column(
        children: [
          // Top app selector bar (horizontal scrolling)
          _MobileAppSelector(modalManager: modalManager),
          // Workspace with split view (max 2 apps)
          Expanded(
            child: _MobileSplitWorkspace(
              modalManager: modalManager,
              stickyNotesManager: stickyNotesManager,
            ),
          ),
          // Bottom input bar (centered for mobile)
          _MobileInputBar(modalManager: modalManager),
        ],
      ),
    );
  }
}

/// Horizontal scrolling app selector bar with circular icons
class _MobileAppSelector extends StatelessWidget {
  final VosModalManager modalManager;

  const _MobileAppSelector({required this.modalManager});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false, // Only apply to top
        child: SizedBox(
          height: 72,
          child: Row(
        children: [
          // Scrollable app icons
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                AppIcon(
                  appId: 'phone',
                  icon: Icons.phone_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'calendar',
                  icon: Icons.calendar_today_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'reminders',
                  icon: Icons.notifications_active,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'tasks',
                  icon: Icons.check_circle_outline,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'notes',
                  icon: Icons.description_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'browser',
                  icon: Icons.language_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'shop',
                  icon: Icons.shopping_cart_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'chat',
                  icon: Icons.chat_bubble_outline,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'weather',
                  icon: Icons.cloud_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
                const SizedBox(width: 12),
                AppIcon(
                  appId: 'memory',
                  icon: Icons.memory_outlined,
                  size: 48,
                  modalManager: modalManager,
                ),
              ],
            ),
          ),
          // Profile icon on the right
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: CircleIcon(
              icon: Icons.person_outline,
              size: 48,
              useFontAwesome: false,
              backgroundColor: const Color(0xFF303030),
              borderColor: const Color(0xFF212121),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ProfileDialog(),
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

/// Split workspace for mobile (max 2 apps side by side)
class _MobileSplitWorkspace extends StatelessWidget {
  final VosModalManager modalManager;
  final StickyNotesManager stickyNotesManager;

  const _MobileSplitWorkspace({
    required this.modalManager,
    required this.stickyNotesManager,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mobile workspace background (full width, no left padding)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MobileGridPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Split view container
        ListenableBuilder(
          listenable: modalManager,
          builder: (context, child) {
            final openModals = modalManager.openModals;

            // Show max 2 apps
            final visibleModals = openModals.take(2).toList();

            if (visibleModals.isEmpty) {
              return _buildEmptyState();
            }

            if (visibleModals.length == 1) {
              return _buildSingleApp(visibleModals[0]);
            }

            return _buildSplitView(visibleModals[0], visibleModals[1]);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an app above to get started',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleApp(ModalInstance modalInstance) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMobileAppBar(modalInstance),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: modalInstance.modal.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitView(ModalInstance modal1, ModalInstance modal2) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // First app (left half)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMobileAppBar(modal1),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: modal1.modal.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Second app (right half)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMobileAppBar(modal2),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: modal2.modal.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar(ModalInstance modalInstance) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            modalInstance.modal.appIcon,
            size: 20,
            color: const Color(0xFFEDEDED),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              modalInstance.modal.title,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Minimize button
          GestureDetector(
            onTap: () => modalInstance.modal.onMinimize?.call(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.minimize,
                size: 16,
                color: Color(0xFFEDEDED),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Close button
          GestureDetector(
            onTap: () => modalInstance.modal.onClose?.call(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFFEDEDED),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-optimized input bar (centered and adapted)
class _MobileInputBar extends StatelessWidget {
  final VosModalManager modalManager;

  const _MobileInputBar({required this.modalManager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: InputBar(modalManager: modalManager),
          ),
        ),
      ),
    );
  }
}


/// Mobile grid painter (same as desktop but no left padding)
class _MobileGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridColor = Color(0xFF2F2F2F);
    const strokeWidth = 0.5;
    const gridCount = 30; // About 30 grids wide

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
