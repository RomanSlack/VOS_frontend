import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/services/websocket_service.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/router/app_router.dart';
import 'package:vos_app/core/router/app_routes.dart';

/// Global overlay that shows incoming call dialog when agent calls user
class IncomingCallOverlay extends StatefulWidget {
  final Widget child;

  const IncomingCallOverlay({super.key, required this.child});

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  StreamSubscription<IncomingCallPayload>? _incomingCallSubscription;
  IncomingCallPayload? _currentIncomingCall;
  bool _showingDialog = false;

  @override
  void initState() {
    super.initState();
    _setupIncomingCallListener();
  }

  void _setupIncomingCallListener() {
    try {
      final wsService = getIt<WebSocketService>();
      print('📞 IncomingCallOverlay: Setting up listener on WebSocketService');
      _incomingCallSubscription = wsService.incomingCallStream.listen(
        (payload) {
          print('📞 IncomingCallOverlay: Received incoming call event!');
          print('📞 Call ID: ${payload.callId}, From: ${payload.callerAgentId}');
          _onIncomingCall(payload);
        },
        onError: (e) => print('📞 Incoming call stream error: $e'),
      );
      print('📞 IncomingCallOverlay: Listener setup complete');
    } catch (e) {
      print('📞 Could not setup incoming call listener: $e');
    }
  }

  void _onIncomingCall(IncomingCallPayload payload) {
    if (_showingDialog) return; // Already showing a dialog

    _showingDialog = true;
    setState(() {
      _currentIncomingCall = payload;
    });
  }

  void _dismissDialog() {
    _showingDialog = false;
    setState(() {
      _currentIncomingCall = null;
    });
  }

  Future<void> _acceptCall(IncomingCallPayload payload) async {
    _dismissDialog();

    try {
      final callService = getIt<CallService>();
      // Accept the call - this will connect to the call WebSocket
      final accepted = await callService.acceptIncomingCall(payload.callId);
      print('📞 Call accepted: ${payload.callId}, success: $accepted');

      if (accepted) {
        // Navigate to active call page with full call controls
        // Use router directly since we're above GoRouter in widget tree
        print('📞 Navigating to active call page...');
        final router = getIt<AppRouter>();
        router.config.go(AppRoutes.activeCall);
      }
    } catch (e) {
      print('📞 Error accepting call: $e');
    }
  }

  Future<void> _declineCall(IncomingCallPayload payload) async {
    _dismissDialog();

    try {
      final callService = getIt<CallService>();
      await callService.declineIncomingCall(payload.callId);
      print('📞 Call declined: ${payload.callId}');
    } catch (e) {
      print('📞 Error declining call: $e');
    }
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentIncomingCall != null)
          _IncomingCallDialogOverlay(
            payload: _currentIncomingCall!,
            onAccept: () => _acceptCall(_currentIncomingCall!),
            onDecline: () => _declineCall(_currentIncomingCall!),
          ),
      ],
    );
  }
}

/// Overlay version of the incoming call dialog (doesn't need Navigator)
class _IncomingCallDialogOverlay extends StatelessWidget {
  final IncomingCallPayload payload;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallDialogOverlay({
    required this.payload,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: _IncomingCallDialog(
          payload: payload,
          onAccept: onAccept,
          onDecline: onDecline,
        ),
      ),
    );
  }
}

class _IncomingCallDialog extends StatefulWidget {
  final IncomingCallPayload payload;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallDialog({
    required this.payload,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<_IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getCallerName() {
    // Convert agent_id to display name
    switch (widget.payload.callerAgentId) {
      case 'primary_agent':
        return 'V';
      case 'weather_agent':
        return 'Weather Agent';
      case 'calendar_agent':
        return 'Calendar Agent';
      default:
        return widget.payload.callerAgentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caller avatar with pulse animation
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // "Incoming Call" text
            Text(
              'Incoming Call',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Caller name
            Text(
              _getCallerName(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Reason
            if (widget.payload.reason != 'incoming_call')
              Text(
                widget.payload.reason,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 30),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                _CallActionButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onPressed: widget.onDecline,
                  label: 'Decline',
                ),

                // Accept button
                _CallActionButton(
                  icon: Icons.call,
                  color: Colors.green,
                  onPressed: widget.onAccept,
                  label: 'Accept',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String label;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
