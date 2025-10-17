import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/modal_limit_notification.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/router/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VosModalManager? _modalManager;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure GetIt is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _modalManager = VosModalManager();
      });
    });
  }

  @override
  void dispose() {
    _modalManager?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while modal manager is initializing
    if (_modalManager == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF212121),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00BCD4),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const Workspace(), // Grid background behind everything
          Row(
            children: [
              AppRail(modalManager: _modalManager!),
              const Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          // Optimized modal rendering
          _OptimizedModalStack(modalManager: _modalManager!),
          // Modal limit notification
          ModalLimitNotification(modalManager: _modalManager!),
          // Logout button in top-right corner
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleLogout(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303030),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFFF5252), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(modalManager: _modalManager!),
          ),
        ],
      ),
    );
  }
}

// Separate widget to isolate modal rebuilds
class _OptimizedModalStack extends StatelessWidget {
  final VosModalManager modalManager;

  const _OptimizedModalStack({
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modalManager,
      builder: (context, child) {
        final openModals = modalManager.openModals;

        // Only rebuild when modal list actually changes
        return Stack(
          children: openModals.map((modalInstance) {
            return KeyedSubtree(
              key: ValueKey(modalInstance.appId),
              child: modalInstance.modal,
            );
          }).toList(),
        );
      },
    );
  }
}