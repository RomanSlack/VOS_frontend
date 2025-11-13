import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/core/modal_manager.dart';

class ZoomControls extends StatelessWidget {
  final VosModalManager modalManager;

  const ZoomControls({
    super.key,
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: modalManager.zoomLevelNotifier,
          builder: (context, zoomLevel, child) {
            final canZoomIn = zoomLevel < VosModalManager.maxZoom;
            final canZoomOut = zoomLevel > VosModalManager.minZoom;
            final isDefaultZoom = (zoomLevel - 1.0).abs() < 0.01;

            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom Out Button
                  _ZoomButton(
                    icon: Icons.remove,
                    onPressed: canZoomOut ? modalManager.zoomOut : null,
                    tooltip: 'Zoom Out',
                  ),
                  const SizedBox(width: 8),
                  // Zoom Level Display with Reset
                  _ZoomLevelDisplay(
                    zoomLevel: zoomLevel,
                    onTap: !isDefaultZoom ? modalManager.resetZoom : null,
                  ),
                  const SizedBox(width: 8),
                  // Zoom In Button
                  _ZoomButton(
                    icon: Icons.add,
                    onPressed: canZoomIn ? modalManager.zoomIn : null,
                    tooltip: 'Zoom In',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: CircleIcon(
        icon: icon,
        size: 36,
        useFontAwesome: false,
        backgroundColor: onPressed != null
            ? const Color(0xFF424242)
            : const Color(0xFF2A2A2A),
        onPressed: onPressed,
      ),
    );
  }
}

class _ZoomLevelDisplay extends StatefulWidget {
  final double zoomLevel;
  final VoidCallback? onTap;

  const _ZoomLevelDisplay({
    required this.zoomLevel,
    required this.onTap,
  });

  @override
  State<_ZoomLevelDisplay> createState() => _ZoomLevelDisplayState();
}

class _ZoomLevelDisplayState extends State<_ZoomLevelDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoomPercentage = (widget.zoomLevel * 100).round();
    final canReset = widget.onTap != null;

    return Tooltip(
      message: canReset ? 'Reset Zoom (100%)' : 'Zoom Level',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) {
          if (canReset && !_isHovered) {
            setState(() => _isHovered = true);
            _controller.forward();
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
            _controller.reverse();
          }
        },
        cursor: canReset ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isHovered && canReset
                    ? const Color(0xFF424242)
                    : const Color(0xFF383838),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$zoomPercentage%',
                style: TextStyle(
                  color: const Color(0xFFEDEDED),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
