import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A text widget with a bubbly wave animation where letters scale and change shade
/// in a wave pattern moving from left to right and back.
class WaveTextAnimation extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration? waveDuration;
  final ValueNotifier<bool>? isActiveNotifier;

  const WaveTextAnimation({
    super.key,
    required this.text,
    this.style,
    this.waveDuration = const Duration(milliseconds: 1500),
    this.isActiveNotifier,
  });

  @override
  State<WaveTextAnimation> createState() => _WaveTextAnimationState();
}

class _WaveTextAnimationState extends State<WaveTextAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.waveDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If isActiveNotifier is provided, listen to it
    if (widget.isActiveNotifier != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.isActiveNotifier!,
        builder: (context, isActive, child) {
          return _buildWaveText(isActive);
        },
      );
    }

    // Otherwise default to active
    return _buildWaveText(true);
  }

  Widget _buildWaveText(bool isActive) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (index) {
            // Calculate wave position for this letter
            // The wave moves from 0 to 1 across all letters
            final letterPosition = index / widget.text.length;

            // Current wave position (0 to 1, repeating)
            final wavePosition = _controller.value;

            // Calculate distance from wave peak to this letter
            // Use modulo to create a continuous wave that wraps around
            var distanceFromPeak = (letterPosition - wavePosition).abs();
            if (distanceFromPeak > 0.5) {
              distanceFromPeak = 1.0 - distanceFromPeak; // Wrap around
            }

            // Convert distance to wave intensity (0 to 1, where 1 is at peak)
            // Use a wider wave with cosine for smooth bulging effect
            final waveIntensity = math.max(
              0.0,
              math.cos(distanceFromPeak * math.pi * 2) * 0.5 + 0.5,
            );

            // Reduce animation intensity when inactive (10% of normal)
            final animationMultiplier = isActive ? 1.0 : 0.1;

            // Scale: 1.0 to 1.3 based on wave intensity (or 1.0 to 1.03 when inactive)
            final scale = 1.0 + (waveIntensity * 0.3 * animationMultiplier);

            // Brightness: Make letters brighter at wave peak (subtle when inactive)
            // HSL: Increase lightness for the wave effect
            final baseColor = widget.style?.color ?? Colors.white;
            final hslColor = HSLColor.fromColor(baseColor);
            final brightColor = hslColor
                .withLightness(
                  (hslColor.lightness + (waveIntensity * 0.2 * animationMultiplier))
                      .clamp(0.0, 1.0),
                )
                .toColor();

            return Transform.scale(
              scale: scale,
              child: Text(
                widget.text[index],
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: brightColor,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
