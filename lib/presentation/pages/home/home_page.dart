import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/modal_limit_notification.dart';
import 'package:vos_app/presentation/widgets/vos_modal.dart';
import 'package:vos_app/core/modal_manager.dart';

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
        final minimizedModals = modalManager.minimizedModals;

        // Combine all modals into one list to maintain consistent keys
        final allModals = [...openModals, ...minimizedModals];

        // Render all modals with consistent keys
        // Modals handle their own visibility based on state
        return Stack(
          children: allModals.map((modalInstance) {
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