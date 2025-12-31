import 'dart:async';

import 'package:flutter/material.dart';

/// Timer widget showing call duration
class CallTimer extends StatefulWidget {
  final DateTime startTime;
  final bool isPaused;
  final TextStyle? style;

  const CallTimer({
    super.key,
    required this.startTime,
    this.isPaused = false,
    this.style,
  });

  @override
  State<CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<CallTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(CallTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _stopTimer();
      } else {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });

    // Initial update
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTime);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_elapsed),
      style: widget.style ??
          const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}
