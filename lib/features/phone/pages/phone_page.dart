import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/features/phone/widgets/call_button.dart';
import 'package:vos_app/features/phone/widgets/floating_call_overlay.dart';

/// Main phone app page
///
/// Shows:
/// - Large call button to initiate a call
/// - Recent calls list (future)
/// - Quick-dial agent avatars (future)
class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  late CallService _callService;
  final SessionService _sessionService = SessionService();

  bool _isConnecting = false;
  bool _isLoadingHistory = false;
  List<CallHistoryItem> _callHistory = [];
  bool _showCallOverlay = false;

  @override
  void initState() {
    super.initState();
    _callService = context.read<CallService>();

    // Listen for call state changes
    _callService.callStateStream.listen(_onCallStateChanged);

    // Listen for incoming calls
    _callService.incomingCallStream.listen(_onIncomingCall);

    // Listen for errors
    _callService.errorStream.listen((error) {
       _showError(error);
       if (mounted) setState(() => _isConnecting = false);
    });

    // Check for existing active call on init and load history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_callService.isOnCall) {
        debugPrint('📞 Active call detected, showing call overlay');
        setState(() => _showCallOverlay = true);
      }
      _loadCallHistory();
    });
  }

  Future<void> _loadCallHistory() async {
    if (_isLoadingHistory) return;

    setState(() => _isLoadingHistory = true);

    try {
      final sessionId = await _sessionService.getSessionId();
      final response = await _callService.getCallHistory(sessionId: sessionId);

      if (response != null && mounted) {
        setState(() {
          _callHistory = response.calls;
        });
      }
    } catch (e) {
      debugPrint('Error loading call history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _onCallStateChanged(CallState state) {
    if (!mounted) return;

    // Show overlay when call is active
    if (state == CallState.connected ||
        state == CallState.ringingOutbound ||
        state == CallState.ringingInbound ||
        state == CallState.onHold) {
      setState(() => _showCallOverlay = true);
    } else if (state == CallState.ended || state == CallState.idle) {
      // Hide overlay when call ends (with small delay for visual feedback)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _showCallOverlay = false);
          _loadCallHistory(); // Refresh history after call
        }
      });
    }
  }

  void _onIncomingCall(IncomingCallPayload payload) {
    if (!mounted) return;

    // Show incoming call dialog
    _showIncomingCallDialog(payload);
  }

  void _dismissCallOverlay() {
    setState(() => _showCallOverlay = false);
  }

  Future<void> _initiateCall() async {
    setState(() => _isConnecting = true);

    try {
      // Ensure connected to WebSocket
      final sessionId = await _sessionService.getSessionId();

      final connected = await _callService.connect(sessionId);
      if (!connected) {
        _showError('Failed to connect');
        return;
      }

      // Initiate call
      final success = await _callService.initiateCall();
      if (!success) {
        // Error will be emitted via errorStream if specific, 
        // otherwise this generic one might show if stream didn't fire
        // _showError('Failed to initiate call'); 
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      // _isConnecting is reset in errorStream listener or valid connection logic
      // But we keep it here as safety net
      if (mounted) {
         // specific errors reset connect state via listener
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showIncomingCallDialog(IncomingCallPayload payload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _formatAgentName(payload.callerAgentId),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              payload.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _callService.declineCall(payload.callId);
              Navigator.of(context).pop();
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _callService.acceptCall(payload.callId);
              Navigator.of(context).pop();
              setState(() => _showCallOverlay = true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  String _formatAgentName(String agentId) {
    return agentId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Agent quick-dial section (future)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Agent avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'VOS Assistant',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to call',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Call button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: CallButton(
                    onPressed: _isConnecting ? null : _initiateCall,
                    isLoading: _isConnecting,
                  ),
                ),

                // Recent calls section
                _buildCallHistorySection(),
              ],
            ),
          ),

          // Floating call overlay (PiP style)
          if (_showCallOverlay)
            FloatingCallOverlay(
              callService: _callService,
              onDismiss: _dismissCallOverlay,
            ),
        ],
      ),
    );
  }

  Widget _buildCallHistorySection() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_callHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'No recent calls',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recent Calls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _callHistory.length,
              itemBuilder: (context, index) {
                final call = _callHistory[index];
                return _buildCallHistoryItem(call);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(CallHistoryItem call) {
    final theme = Theme.of(context);

    // Determine call icon and color
    IconData icon;
    Color iconColor;

    if (call.wasMissed) {
      icon = Icons.call_missed;
      iconColor = Colors.red;
    } else if (call.wasIncoming) {
      icon = Icons.call_received;
      iconColor = Colors.green;
    } else {
      icon = Icons.call_made;
      iconColor = Colors.blue;
    }

    // Format time
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');
    final now = DateTime.now();
    final isToday = call.startedAt.day == now.day &&
        call.startedAt.month == now.month &&
        call.startedAt.year == now.year;

    final timeStr = isToday
        ? timeFormat.format(call.startedAt)
        : dateFormat.format(call.startedAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        _formatAgentName(call.currentAgentId),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: call.wasMissed ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            call.wasIncoming ? 'Incoming' : 'Outgoing',
            style: theme.textTheme.bodySmall,
          ),
          if (call.wasAnswered) ...[
            const Text(' · '),
            Text(
              call.formattedDuration,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      trailing: Text(
        timeStr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey,
        ),
      ),
      onTap: () {
        // Could show call details or callback
        _initiateCall();
      },
    );
  }
}
