import 'package:flutter/material.dart';
import 'package:vos_app/core/modal_manager.dart';

class ModalLimitNotification extends StatefulWidget {
  final VosModalManager modalManager;

  const ModalLimitNotification({
    super.key,
    required this.modalManager,
  });

  @override
  State<ModalLimitNotification> createState() => _ModalLimitNotificationState();
}

class _ModalLimitNotificationState extends State<ModalLimitNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.modalManager,
      builder: (context, child) {
        final shouldShow = widget.modalManager.showLimitNotification;

        // Only trigger animation when state actually changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (shouldShow) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        });

        return Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_opacityAnimation.value == 0.0) {
                  return const SizedBox.shrink();
                }

                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _NotificationCard(modalManager: widget.modalManager),
            ),
          ),
        );
      },
    );
  }
}

// Separate the notification card to prevent rebuilds
class _NotificationCard extends StatelessWidget {
  final VosModalManager modalManager;

  const _NotificationCard({
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0x4DFF9800),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTip(),
            const SizedBox(height: 16),
            _OptimizedAppPreview(modalManager: modalManager),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x33FF9800),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maximum Apps Reached',
                style: TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'You can only have 4 apps open at once',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => modalManager.dismissLimitNotification(),
          icon: const Icon(
            Icons.close,
            color: Color(0xFF757575),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Color(0xFFFFEB3B),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'Close or minimize an app to open a new one',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized app preview that only rebuilds when modal list changes
class _OptimizedAppPreview extends StatelessWidget {
  final VosModalManager modalManager;

  const _OptimizedAppPreview({
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x4D424242),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Currently Open:',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildAppPreviews(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppPreviews() {
    final openApps = modalManager.openModals;
    final minimizedApps = modalManager.minimizedModals;
    final previews = <Widget>[];

    for (final modal in openApps.take(4)) {
      final app = VosModalManager.apps.firstWhere((app) => app.id == modal.appId);
      previews.add(_AppPreviewIcon(
        icon: app.icon,
        isMinimized: false,
      ));
    }

    for (final modal in minimizedApps.take(4 - openApps.length)) {
      final app = VosModalManager.apps.firstWhere((app) => app.id == modal.appId);
      previews.add(_AppPreviewIcon(
        icon: app.icon,
        isMinimized: true,
      ));
    }

    return previews;
  }
}

// Reusable app preview icon
class _AppPreviewIcon extends StatelessWidget {
  final IconData icon;
  final bool isMinimized;

  const _AppPreviewIcon({
    required this.icon,
    required this.isMinimized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isMinimized
            ? const Color(0x33FF9800)
            : const Color(0x334CAF50),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMinimized
              ? const Color(0xFFFF9800)
              : const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isMinimized
            ? const Color(0xFFFF9800)
            : const Color(0xFF4CAF50),
      ),
    );
  }

}