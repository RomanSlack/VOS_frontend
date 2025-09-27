import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/modal_limit_notification.dart';
import 'package:vos_app/core/modal_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VosModalManager _modalManager;

  @override
  void initState() {
    super.initState();
    _modalManager = VosModalManager();
  }

  @override
  void dispose() {
    _modalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Workspace(), // Grid background behind everything
          Row(
            children: [
              AppRail(modalManager: _modalManager),
              const Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          // Optimized modal rendering
          _OptimizedModalStack(modalManager: _modalManager),
          // Modal limit notification
          ModalLimitNotification(modalManager: _modalManager),
          Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(modalManager: _modalManager),
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