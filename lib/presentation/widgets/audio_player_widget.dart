import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Simple audio player widget for voice messages (web-only)
class AudioPlayerWidget extends StatefulWidget {
  final String audioFilePath;
  final bool autoPlay;

  const AudioPlayerWidget({
    super.key,
    required this.audioFilePath,
    this.autoPlay = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _hasCompleted = false;
      });

      // Set the audio source from URL
      // audioFilePath is a full URL (e.g., "https://api.jarvos.dev/api/v1/audio/...")
      debugPrint('🎵 Loading audio from: ${widget.audioFilePath}');
      await _player.setUrl(widget.audioFilePath);
      debugPrint('✅ Audio loaded successfully');

      setState(() {
        _isLoading = false;
      });
      debugPrint('🎵 State after load: isLoading=$_isLoading, hasError=$_hasError, isPlaying=$_isPlaying');

      // Listen to player state (handles both playing state and completion)
      _player.playerStateStream.listen((state) {
        if (mounted) {
          debugPrint('🎵 Player state changed: playing=${state.playing}, processingState=${state.processingState}');

          // Check if audio has completed
          if (state.processingState == ProcessingState.completed) {
            debugPrint('✅ Audio playback completed');
            setState(() {
              _hasCompleted = true;
              _isPlaying = false;
            });
          } else {
            // Normal play/pause state update
            setState(() {
              _isPlaying = state.playing;
              // Reset completion flag if we're playing again
              if (state.playing) {
                _hasCompleted = false;
              }
            });
          }

          debugPrint('🎵 UI state updated: isPlaying=$_isPlaying, hasCompleted=$_hasCompleted');
        }
      });

      // Listen to duration changes
      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
          debugPrint('🎵 Audio duration: ${_formatDuration(duration)}');
        }
      });

      // Listen to position changes
      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Auto-play if requested
      if (widget.autoPlay) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize audio player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      debugPrint('🎵 Toggle play/pause: isPlaying=$_isPlaying, hasCompleted=$_hasCompleted');

      if (_isPlaying) {
        await _player.pause();
        debugPrint('⏸️ Paused audio');
      } else {
        // If audio has completed, reset player before replaying
        if (_hasCompleted) {
          debugPrint('🔄 Replaying from start');
          // Stop the player to fully reset the completed state
          await _player.stop();
          // Seek back to the beginning
          await _player.seek(Duration.zero);
          setState(() {
            _hasCompleted = false;
          });
          debugPrint('🔄 Player reset and ready to play');
        }
        await _player.play();
        debugPrint('▶️ Playing audio');
      }
    } catch (e) {
      debugPrint('❌ Failed to toggle play/pause: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _hasError || _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hasError
                    ? Colors.red.withOpacity(0.5)
                    : const Color(0xFF00BCD4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _hasError
                            ? Icons.error_outline
                            : (_isPlaying ? Icons.pause : Icons.play_arrow),
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress bar
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hasError ? Colors.red.withOpacity(0.5) : const Color(0xFF00BCD4),
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),

                // Duration text
                Text(
                  _hasError
                      ? 'Failed to load'
                      : _isLoading
                          ? 'Loading...'
                          : '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    color: _hasError ? Colors.red.withOpacity(0.7) : const Color(0xFF757575),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Speaker icon
          Icon(
            _hasError ? Icons.volume_off : Icons.volume_up,
            color: _hasError ? Colors.red.withOpacity(0.5) : const Color(0xFF00BCD4),
            size: 16,
          ),
        ],
      ),
    );
  }
}
