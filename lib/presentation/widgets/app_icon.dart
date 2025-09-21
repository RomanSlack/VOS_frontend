import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/core/modal_manager.dart';

class AppIcon extends StatefulWidget {
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
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _wasMinimized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.modalManager,
      builder: (context, child) {
        final isOpen = widget.modalManager.isModalOpen(widget.appId);
        final isMinimized = widget.modalManager.isModalMinimized(widget.appId);

        // Only start/stop pulse animation when state actually changes
        if (isMinimized && !_wasMinimized) {
          _pulseController.repeat(reverse: true);
        } else if (!isMinimized && _wasMinimized) {
          _pulseController.stop();
          _pulseController.reset();
        }
        _wasMinimized = isMinimized;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIcon(
              icon: widget.icon,
              size: widget.size,
              useFontAwesome: false,
              backgroundColor: isOpen && !isMinimized
                  ? const Color(0xFF424242)
                  : null,
              onPressed: () => widget.modalManager.openModal(widget.appId),
            ),

            // State indicators - only build when needed
            if (isOpen && !isMinimized) _buildOpenIndicator(),
            if (isMinimized) _buildMinimizedIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildOpenIndicator() {
    return const Positioned(
      top: -2,
      right: -2,
      child: _StateIndicator(
        color: Color(0xFF4CAF50),
        size: 12,
      ),
    );
  }

  Widget _buildMinimizedIndicator() {
    return Positioned(
      top: -2,
      right: -2,
      child: Stack(
        children: [
          const _StateIndicator(
            color: Color(0xFFFF9800),
            size: 12,
            icon: Icons.minimize,
          ),
          // Optimized pulse border
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xFFFF9800).withOpacity(0.2),
                        const Color(0xFFFF9800).withOpacity(0.6),
                        _pulseAnimation.value,
                      )!,
                      width: 1 + _pulseAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized reusable state indicator
class _StateIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final IconData? icon;

  const _StateIndicator({
    required this.color,
    required this.size,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF303030),
          width: 2,
        ),
      ),
      child: icon != null
          ? Center(
              child: Icon(
                icon,
                size: size * 0.6,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}