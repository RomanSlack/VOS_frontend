import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vos_app/core/router/app_routes.dart';

import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/features/phone/widgets/call_timer.dart';

/// Floating PiP-style call overlay
///
/// A small draggable window that shows during active calls.
/// Can be minimized to just show avatar, or expanded for controls.
class FloatingCallOverlay extends StatefulWidget {
  final CallService callService;
  final VoidCallback? onDismiss;

  const FloatingCallOverlay({
    super.key,
    required this.callService,
    this.onDismiss,
  });

  @override
  State<FloatingCallOverlay> createState() => _FloatingCallOverlayState();
}

class _FloatingCallOverlayState extends State<FloatingCallOverlay> {
  // Position
  Offset _position = const Offset(20, 100);
  bool _isExpanded = true;

  // Subscriptions
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _callSubscription;
  StreamSubscription? _agentSpeakingSubscription;

  // State
  CallState _callState = CallState.idle;
  Call? _currentCall;
  bool _agentSpeaking = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    _callState = widget.callService.callState;
    _currentCall = widget.callService.currentCall;
    _isMuted = widget.callService.isMuted;

    _callStateSubscription = widget.callService.callStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _callState = state);

      // Auto-dismiss when call ends or disconnects
      if (state == CallState.ended || state == CallState.idle) {
         // Immediate dismissal for better UX
         widget.onDismiss?.call();
      }
    });

    _callSubscription = widget.callService.callStream.listen((call) {
      if (!mounted) return;
      setState(() => _currentCall = call);
    });

    _agentSpeakingSubscription =
        widget.callService.agentSpeakingStream.listen((speaking) {
      if (!mounted) return;
      setState(() => _agentSpeaking = speaking);
    });
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    _callSubscription?.cancel();
    _agentSpeakingSubscription?.cancel();
    super.dispose();
  }

  void _toggleMute() {
    widget.callService.toggleMute();
    setState(() => _isMuted = widget.callService.isMuted);
  }

  void _endCall() async {
    await widget.callService.endCall();
  }

  void _interruptAudio() async {
    await widget.callService.interruptAudio();
  }

  String _formatAgentName(String? agentId) {
    if (agentId == null) return 'VOS';
    final name = agentId.replaceAll('_agent', '').replaceAll('_', ' ');
    return name[0].toUpperCase() + name.substring(1);
  }

  String _getStatusText() {
    switch (_callState) {
      case CallState.ringingOutbound:
        return 'Calling...';
      case CallState.ringingInbound:
        return 'Incoming';
      case CallState.connected:
        return _agentSpeaking ? 'Speaking' : 'Connected';
      case CallState.onHold:
        return 'On Hold';
      case CallState.ending:
        return 'Ending...';
      case CallState.ended:
        return 'Ended';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx.clamp(0, screenSize.width - (_isExpanded ? 200 : 70)),
      top: _position.dy.clamp(0, screenSize.height - (_isExpanded ? 180 : 70)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 35),
          color: Colors.grey[900],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 200 : 70,
            height: _isExpanded ? 180 : 70,
            padding: const EdgeInsets.all(12),
            child: _isExpanded ? _buildExpanded(context) : _buildMinimized(),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimized() {
    return Stack(
      children: [
        // Avatar with speaking indicator
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: _agentSpeaking ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.smart_toy,
            size: 24,
            color: Colors.blue,
          ),
        ),
        // Call state indicator
        if (_callState == CallState.ringingOutbound ||
            _callState == CallState.ringingInbound)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row - Tap to open full screen
        GestureDetector(
          onTap: () {
            // Navigate to active call page
            // Use pushNamed so we can return to this overlay state
            GoRouter.of(context).pushNamed(AppRoutes.activeCall);
          },
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _agentSpeaking ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatAgentName(_currentCall?.currentAgentId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_full,
                          size: 10,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Timer
        if (_callState == CallState.connected || _callState == CallState.onHold)
          CallTimer(
            startTime: _currentCall?.connectedAt ?? DateTime.now(),
            isPaused: _callState == CallState.onHold,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

        const Spacer(),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _isMuted ? Icons.mic_off : Icons.mic,
                color: _isMuted ? Colors.red : Colors.white,
              ),
              iconSize: 24,
            ),
            // Stop audio button (only show when agent is speaking)
            if (_agentSpeaking)
              IconButton(
                onPressed: _interruptAudio,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.orange),
                iconSize: 24,
                tooltip: 'Stop audio',
              ),
            // End call button
            Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _endCall,
                icon: const Icon(Icons.call_end, color: Colors.white),
                iconSize: 24,
              ),
            ),
            // Minimize button (hide when stop button is visible to save space)
            if (!_agentSpeaking)
              IconButton(
                onPressed: () => setState(() => _isExpanded = false),
                icon: const Icon(Icons.minimize, color: Colors.white70),
                iconSize: 24,
              ),
          ],
        ),
      ],
    );
  }
}
