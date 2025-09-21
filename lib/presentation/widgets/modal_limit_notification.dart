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
    return AnimatedBuilder(
      animation: widget.modalManager,
      builder: (context, child) {
        if (widget.modalManager.showLimitNotification) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        return Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: _buildNotificationCard(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
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
                  onPressed: () {
                    widget.modalManager.dismissLimitNotification();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF757575),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFFEB3B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Close or minimize an app to open a new one',
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildOpenAppsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAppsPreview() {
    final openApps = widget.modalManager.openModals;
    final minimizedApps = widget.modalManager.minimizedModals;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242).withOpacity(0.3),
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
            children: [
              ...openApps.take(4).map((modal) => _buildAppPreview(
                modal.appId,
                VosModalManager.apps.firstWhere((app) => app.id == modal.appId).icon,
                isMinimized: false,
              )),
              ...minimizedApps.take(4 - openApps.length).map((modal) => _buildAppPreview(
                modal.appId,
                VosModalManager.apps.firstWhere((app) => app.id == modal.appId).icon,
                isMinimized: true,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreview(String appId, IconData icon, {required bool isMinimized}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isMinimized ? const Color(0xFFFF9800).withOpacity(0.2) : const Color(0xFF4CAF50).withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMinimized ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isMinimized ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
      ),
    );
  }
}