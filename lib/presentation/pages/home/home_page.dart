import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/vos_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showDemoModal = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Workspace(), // Grid background behind everything
          const Row(
            children: [
              AppRail(),
              Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          if (_showDemoModal)
            VosModal(
              appIcon: Icons.chat_bubble_outline,
              title: "Chat App",
              initialWidth: 450,
              initialHeight: 350,
              initialPosition: const Offset(200, 80),
              onClose: () {
                setState(() {
                  _showDemoModal = false;
                });
              },
              onMinimize: () {
                setState(() {
                  _showDemoModal = false;
                });
              },
              child: Container(
                color: const Color(0xFF212121),
                child: const Center(
                  child: Text(
                    'Demo Modal Content\n\nThis modal can be:\n• Dragged around\n• Resized from bottom-right\n• Minimized\n• Fullscreened\n• Closed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(),
          ),
        ],
      ),
    );
  }
}