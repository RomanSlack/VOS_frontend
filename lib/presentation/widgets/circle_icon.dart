import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  const CircleIcon({
    super.key,
    required this.icon,
    this.size = 36,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              icon,
              size: size * 0.5, // Icon is 50% of circle size
              color: const Color(0xFFEDEDED),
            ),
          ),
        ),
      ),
    );
  }
}