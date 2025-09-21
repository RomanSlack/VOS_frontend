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
          // Render all open modals
          AnimatedBuilder(
            animation: _modalManager,
            builder: (context, child) {
              return Stack(
                children: _modalManager.openModals.map((modalInstance) {
                  return modalInstance.modal;
                }).toList(),
              );
            },
          ),
          // Modal limit notification
          ModalLimitNotification(modalManager: _modalManager),
          const Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(),
          ),
        ],
      ),
    );
  }
}