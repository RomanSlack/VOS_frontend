import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircleIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool useFontAwesome;

  const CircleIcon({
    super.key,
    required this.icon,
    this.size = 36,
    this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.useFontAwesome = true,
  });

  @override
  State<CircleIcon> createState() => _CircleIconState();
}

class _CircleIconState extends State<CircleIcon> with SingleTickerProviderStateMixin {
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
      end: 1.1,
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? const Color(0xFF424242),
                    shape: BoxShape.circle,
                    border: widget.borderColor != null
                        ? Border.all(
                            color: widget.borderColor!,
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
                        offset: Offset(0, _isHovered ? 3 : 2),
                        blurRadius: _isHovered ? 6 : 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.useFontAwesome
                        ? FaIcon(
                            widget.icon,
                            size: widget.size * 0.5,
                            color: const Color(0xFFEDEDED),
                          )
                        : Icon(
                            widget.icon,
                            size: widget.size * 0.5,
                            color: const Color(0xFFEDEDED),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}