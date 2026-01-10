import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:vos_app/core/models/call_models.dart';
import 'package:vos_app/core/router/app_routes.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/features/phone/widgets/call_controls.dart';
import 'package:vos_app/features/phone/widgets/call_timer.dart';

/// Active call screen
///
/// Shows:
/// - Agent avatar and name
/// - Call duration timer
/// - Live transcription overlay
/// - Call controls (mute, hold, end)
class ActiveCallPage extends StatefulWidget {
  const ActiveCallPage({super.key});

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  late CallService _callService;

  // Subscriptions
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _callSubscription;
  StreamSubscription? _transcriptSubscription;
  StreamSubscription? _agentSpeakingSubscription;

  // State
  CallState _callState = CallState.idle;
  Call? _currentCall;
  final List<CallTranscript> _transcripts = [];
  bool _agentSpeaking = false;
  bool _isMuted = false;
  bool _isOnHold = false;

  // Ringtone
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  bool _isRingtoneLoaded = false;
  DateTime? _ringtoneStartTime;

  @override
  void initState() {
    super.initState();
    _callService = context.read<CallService>();

    // Initialize state
    _callState = _callService.callState;
    _currentCall = _callService.currentCall;
    _isMuted = _callService.isMuted;

    // Initialize ringtone
    _initRingtone();

    // Start ringtone if already in ringing state
    if (_callState == CallState.ringingOutbound || _callState == CallState.ringingInbound) {
      _playRingtone();
    }

    // Subscribe to streams
    _callStateSubscription = _callService.callStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _callState = state;
        _isOnHold = state == CallState.onHold;
      });

      // Handle ringtone
      debugPrint('🔔 Call state changed to: $state (ringtone loaded: $_isRingtoneLoaded, playing: ${_ringtonePlayer.playing})');
      if (state == CallState.ringingOutbound || state == CallState.ringingInbound) {
        debugPrint('🔔 Ringing state - should play ringtone');
        _playRingtone();
      } else if (state == CallState.connected || state == CallState.ended || state == CallState.idle) {
        debugPrint('🔔 Non-ringing state ($state) - stopping ringtone');
        _stopRingtone();
      }

      // Close if call ended - go back to home
      if (state == CallState.ended || state == CallState.idle) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            // Navigate to home after call ends
            context.go(AppRoutes.home);
          }
        });
      }
    });

    _callSubscription = _callService.callStream.listen((call) {
      if (!mounted) return;
      setState(() => _currentCall = call);
    });

    _transcriptSubscription = _callService.transcriptStream.listen((transcript) {
      if (!mounted) return;
      setState(() {
        _transcripts.add(transcript);
        // Keep only last 10 transcripts
        if (_transcripts.length > 10) {
          _transcripts.removeAt(0);
        }
      });
    });

    _agentSpeakingSubscription =
        _callService.agentSpeakingStream.listen((speaking) {
      if (!mounted) return;
      setState(() => _agentSpeaking = speaking);
    });
  }

  Future<void> _initRingtone() async {
    try {
      debugPrint('Loading ringtone asset...');
      await _ringtonePlayer.setAsset('assets/audio/oppo_calm.mp3');
      await _ringtonePlayer.setLoopMode(LoopMode.one);
      await _ringtonePlayer.setVolume(0.0);
      _isRingtoneLoaded = true;
      debugPrint('Ringtone loaded successfully');

      // If already in ringing state when ringtone loads, start playing
      if (_callState == CallState.ringingOutbound || _callState == CallState.ringingInbound) {
        debugPrint('Already in ringing state, starting ringtone');
        _playRingtone();
      }
    } catch (e) {
      debugPrint('Failed to load ringtone: $e');
    }
  }

  Future<void> _playRingtone() async {
    if (!_isRingtoneLoaded || _ringtonePlayer.playing) return;
    try {
      _ringtoneStartTime = DateTime.now();
      await _ringtonePlayer.seek(Duration.zero);
      await _ringtonePlayer.setVolume(0.0);
      await _ringtonePlayer.play();

      // Fade in
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_ringtonePlayer.playing) {
          await _ringtonePlayer.setVolume(i * 0.06);
        } else {
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to play ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRingtoneLoaded || !_ringtonePlayer.playing) return;

    // Minimum 1.5 seconds before stopping
    if (_ringtoneStartTime != null) {
      final elapsed = DateTime.now().difference(_ringtoneStartTime!);
      if (elapsed.inMilliseconds < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
      }
    }

    try {
      final currentVolume = _ringtonePlayer.volume;
      for (int i = 10; i >= 0; i--) {
        await Future.delayed(const Duration(milliseconds: 30));
        if (_ringtonePlayer.playing) {
          await _ringtonePlayer.setVolume(currentVolume * i / 10);
        } else {
          break;
        }
      }
      await _ringtonePlayer.pause();
      await _ringtonePlayer.seek(Duration.zero);
      _ringtoneStartTime = null;
    } catch (e) {
      debugPrint('Failed to stop ringtone: $e');
    }
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    _callSubscription?.cancel();
    _transcriptSubscription?.cancel();
    _agentSpeakingSubscription?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  void _toggleMute() {
    _callService.toggleMute();
    setState(() => _isMuted = _callService.isMuted);
  }

  void _toggleHold() async {
    if (_isOnHold) {
      await _callService.resumeCall();
    } else {
      await _callService.holdCall();
    }
  }

  void _endCall() async {
    await _callService.endCall();
  }

  /// Handle back button - just go back, call continues in background
  void _onBackPressed() {
    // Just navigate back without ending the call
    // User can return to call from phone page if call is still active
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatAgentName(String? agentId) {
    if (agentId == null) return 'VOS Assistant';
    return agentId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getStatusText() {
    switch (_callState) {
      case CallState.ringingOutbound:
        return 'Calling...';
      case CallState.ringingInbound:
        return 'Incoming call';
      case CallState.connected:
        return _agentSpeaking ? 'Speaking...' : 'Connected';
      case CallState.onHold:
        return 'On Hold';
      case CallState.transferring:
        return 'Transferring...';
      case CallState.ending:
        return 'Ending call...';
      case CallState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _onBackPressed,
                  ),
                  const Spacer(),
                  // Speaker button (future)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Agent avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _agentSpeaking ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 60,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 24),

            // Agent name
            Text(
              _formatAgentName(_currentCall?.currentAgentId),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Status text
            Text(
              _getStatusText(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 8),

            // Call timer
            if (_callState == CallState.connected ||
                _callState == CallState.onHold)
              CallTimer(
                startTime: _currentCall?.connectedAt ?? DateTime.now(),
                isPaused: _isOnHold,
              ),

            const Spacer(),

            // Transcription overlay
            if (_transcripts.isNotEmpty)
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _transcripts.length,
                  itemBuilder: (context, index) {
                    final transcript =
                        _transcripts[_transcripts.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            transcript.isUser ? Icons.person : Icons.smart_toy,
                            size: 16,
                            color:
                                transcript.isUser ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              transcript.content,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Call controls
            if (_callState == CallState.connected ||
                _callState == CallState.onHold)
              CallControls(
                isMuted: _isMuted,
                isOnHold: _isOnHold,
                onMutePressed: _toggleMute,
                onHoldPressed: _toggleHold,
                onEndPressed: _endCall,
              ),

            // Ringing state - show cancel button
            if (_callState == CallState.ringingOutbound)
              Padding(
                padding: const EdgeInsets.all(32),
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
