import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/core/modal_manager.dart';

class AppIcon extends StatelessWidget {
  final String appId;
  final IconData icon;
  final double size;
  final VosModalManager modalManager;

  const AppIcon({
    super.key,
    required this.appId,
    required this.icon,
    required this.size,
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: modalManager,
      builder: (context, child) {
        final isOpen = modalManager.isModalOpen(appId);
        final isMinimized = modalManager.isModalMinimized(appId);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIcon(
              icon: icon,
              size: size,
              useFontAwesome: false,
              backgroundColor: isOpen && !isMinimized
                  ? const Color(0xFF424242) // Normal active state
                  : null, // Default state
              onPressed: () => modalManager.openModal(appId),
            ),

            // Open indicator dot
            if (isOpen && !isMinimized)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // Green for open
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF303030),
                      width: 2,
                    ),
                  ),
                ),
              ),

            // Minimized indicator
            if (isMinimized)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800), // Orange for minimized
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF303030),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.minimize,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Pulsing animation for minimized apps
            if (isMinimized)
              Positioned.fill(
                child: _buildPulsingBorder(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPulsingBorder() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF9800).withOpacity(0.3 + (0.4 * value)),
              width: 2 + (2 * value),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (modalManager.isModalMinimized(appId)) {
          // Animation will restart automatically due to TweenAnimationBuilder
        }
      },
    );
  }
}