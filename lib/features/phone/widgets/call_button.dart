import 'package:flutter/material.dart';

/// Large circular call button for initiating calls
class CallButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final double size;

  const CallButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed == null
              ? Colors.grey
              : Colors.green,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  Icons.call,
                  size: size * 0.5,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
