import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/presentation/widgets/app_icon.dart';
import 'package:vos_app/presentation/widgets/profile_dialog.dart';
import 'package:vos_app/core/modal_manager.dart';

class AppRail extends StatelessWidget {
  final VosModalManager modalManager;

  const AppRail({
    super.key,
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 48;
    const double iconSpacing = 12;

    return Container(
      width: 80,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(4, 0),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 0),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Main app icons
          AppIcon(
            appId: 'phone',
            icon: Icons.phone_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'calendar',
            icon: Icons.calendar_today_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'tasks',
            icon: Icons.check_circle_outline,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'notes',
            icon: Icons.description_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'browser',
            icon: Icons.language_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'shop',
            icon: Icons.shopping_cart_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'chat',
            icon: Icons.chat_bubble_outline,
            size: iconSize,
            modalManager: modalManager,
          ),
          const SizedBox(height: iconSpacing),
          AppIcon(
            appId: 'weather',
            icon: Icons.cloud_outlined,
            size: iconSize,
            modalManager: modalManager,
          ),

          // Double spacing before plus icon
          const SizedBox(height: iconSpacing * 4),
          CircleIcon(
            icon: Icons.add_outlined,
            size: iconSize,
            useFontAwesome: false,
            onPressed: () {},
          ),

          // Spacer to push user icon to bottom
          const Spacer(),

          // User icon at bottom with special styling
          Builder(
            builder: (context) => CircleIcon(
              icon: Icons.person_outline,
              size: iconSize,
              useFontAwesome: false,
              backgroundColor: const Color(0xFF303030),
              borderColor: const Color(0xFF212121),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ProfileDialog(),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}