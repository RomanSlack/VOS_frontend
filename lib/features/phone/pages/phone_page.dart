import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/features/phone/widgets/floating_call_overlay.dart';

/// Main phone app page with minimalist design
class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage>
    with SingleTickerProviderStateMixin {
  late CallService _callService;
  late TabController _tabController;
  final SessionService _sessionService = SessionService();

  // Bug 4 fix: Store subscriptions for proper cleanup
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<IncomingCallPayload>? _incomingCallSubscription;

  bool _isConnecting = false;
  bool _isLoadingHistory = false;
  List<CallHistoryItem> _callHistory = [];
  bool _showCallOverlay = false;
  CallState _currentCallState = CallState.idle;

  @override
  void initState() {
    super.initState();
    _callService = context.read<CallService>();
    _tabController = TabController(length: 2, vsync: this);

    // Bug 4 fix: Store subscriptions
    _callStateSubscription =
        _callService.callStateStream.listen(_onCallStateChanged);
    _incomingCallSubscription =
        _callService.incomingCallStream.listen(_onIncomingCall);
    _errorSubscription = _callService.errorStream.listen((error) {
      _showError(error);
      if (mounted) setState(() => _isConnecting = false);
    });

    // Check for existing active call on init and load history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_callService.isOnCall) {
        debugPrint('Active call detected, showing call overlay');
        setState(() => _showCallOverlay = true);
      }
      _loadCallHistory();
    });
  }

  @override
  void dispose() {
    // Bug 4 fix: Cancel all subscriptions
    _callStateSubscription?.cancel();
    _errorSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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

    // Update current state for UI
    setState(() => _currentCallState = state);

    // Bug 1 fix: Reset _isConnecting on successful connection or call end
    if (state == CallState.connected ||
        state == CallState.ringingOutbound ||
        state == CallState.ended ||
        state == CallState.idle) {
      setState(() => _isConnecting = false);
    }

    // Bug 3 fix: Show overlay for all active call states including transitional
    if (state == CallState.connected ||
        state == CallState.ringingOutbound ||
        state == CallState.ringingInbound ||
        state == CallState.onHold ||
        state == CallState.transferring ||
        state == CallState.ending) {
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
    _showIncomingCallDialog(payload);
  }

  void _dismissCallOverlay() {
    setState(() => _showCallOverlay = false);
  }

  Future<void> _initiateCall() async {
    setState(() => _isConnecting = true);

    try {
      final sessionId = await _sessionService.getSessionId();

      final connected = await _callService.connect(sessionId);
      if (!connected) {
        _showError('Failed to connect');
        setState(() => _isConnecting = false);
        return;
      }

      final success = await _callService.initiateCall();
      if (!success) {
        setState(() => _isConnecting = false);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isConnecting = false);
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
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1)
            : word)
        .join(' ');
  }

  String _getStatusText() {
    switch (_currentCallState) {
      case CallState.ringingOutbound:
        return 'Calling...';
      case CallState.ringingInbound:
        return 'Incoming call';
      case CallState.connected:
        return 'On call';
      case CallState.onHold:
        return 'On hold';
      case CallState.transferring:
        return 'Transferring...';
      case CallState.ending:
        return 'Ending...';
      default:
        return 'Tap to call';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCallActive = _isConnecting || _showCallOverlay;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Minimal header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Phone',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Main call area
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with green ring when on call
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: _showCallOverlay
                              ? Border.all(
                                  color: Colors.green,
                                  width: 4,
                                )
                              : null,
                        ),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            size: 70,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'VOS Assistant',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _showCallOverlay ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Call button
                      GestureDetector(
                        onTap: isCallActive ? null : _initiateCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isCallActive
                                ? Colors.grey[400]
                                : Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: isCallActive
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _isConnecting
                              ? const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom tabs section
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Recent'),
                            Tab(text: 'Contacts'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRecentCallsTab(),
                            _buildContactsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating call overlay
          if (_showCallOverlay)
            FloatingCallOverlay(
              callService: _callService,
              onDismiss: _dismissCallOverlay,
            ),
        ],
      ),
    );
  }

  Widget _buildRecentCallsTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No recent calls',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _callHistory.length,
      itemBuilder: (context, index) {
        final call = _callHistory[index];
        return _buildCallHistoryItem(call);
      },
    );
  }

  Widget _buildCallHistoryItem(CallHistoryItem call) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onTap: () => _initiateCall(),
      ),
    );
  }

  Widget _buildContactsTab() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VOS Assistant',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your AI assistant',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
