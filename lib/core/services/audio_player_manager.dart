import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Global audio player manager for VOS.
///
/// Manages all audio players across the app to enable:
/// - Global audio interruption (stop all playing audio when user starts speaking)
/// - Audio source tracking
/// - Centralized playback state management
///
/// Usage:
/// ```dart
/// final manager = AudioPlayerManager();
///
/// // Register a player
/// manager.register('call_audio', myPlayer);
///
/// // Interrupt all audio (e.g., when user starts speaking)
/// await manager.interrupt();
///
/// // Interrupt all except one (e.g., keep background music)
/// await manager.interrupt(except: 'background_music');
///
/// // Unregister when done
/// manager.unregister('call_audio');
/// ```
class AudioPlayerManager {
  // Singleton instance
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal();

  // Registered audio sources (id -> player)
  final Map<String, AudioPlayer> _sources = {};

  // Track which source is currently playing
  String? _currentlyPlaying;

  // Stream controllers for state notifications
  final _playingStateController = StreamController<bool>.broadcast();
  final _currentSourceController = StreamController<String?>.broadcast();

  // Public streams
  Stream<bool> get isPlayingStream => _playingStateController.stream;
  Stream<String?> get currentSourceStream => _currentSourceController.stream;

  // Current state
  bool get isPlaying => _currentlyPlaying != null;
  String? get currentlyPlayingSource => _currentlyPlaying;
  int get registeredCount => _sources.length;

  /// Register an audio player with an identifier.
  ///
  /// The identifier should be unique (e.g., 'call_audio', 'voice_message_123').
  /// If a player with the same ID already exists, it will be replaced.
  void register(String id, AudioPlayer player) {
    // Unregister existing player if any
    if (_sources.containsKey(id)) {
      debugPrint('AudioPlayerManager: Replacing existing player: $id');
      unregister(id);
    }

    _sources[id] = player;
    debugPrint('AudioPlayerManager: Registered player: $id (total: ${_sources.length})');

    // Listen to player state to track currently playing
    player.playerStateStream.listen((state) {
      if (state.playing) {
        _currentlyPlaying = id;
        _playingStateController.add(true);
        _currentSourceController.add(id);
      } else if (_currentlyPlaying == id) {
        // This player stopped
        _currentlyPlaying = null;
        _playingStateController.add(false);
        _currentSourceController.add(null);
      }
    });
  }

  /// Unregister an audio player.
  ///
  /// This should be called when the player is no longer needed
  /// (e.g., when disposing a service or widget).
  void unregister(String id) {
    final player = _sources.remove(id);
    if (player != null) {
      // Stop the player if it's playing
      if (_currentlyPlaying == id) {
        _currentlyPlaying = null;
        _playingStateController.add(false);
        _currentSourceController.add(null);
      }
      debugPrint('AudioPlayerManager: Unregistered player: $id (total: ${_sources.length})');
    }
  }

  /// Interrupt (stop) all playing audio.
  ///
  /// Optionally exclude a specific source from being interrupted.
  /// This is useful when you want to stop call audio but keep background music.
  ///
  /// [except] - Optional ID of a player to NOT interrupt
  /// [clearQueue] - Whether to also clear any queued audio (default: true)
  Future<void> interrupt({String? except, bool clearQueue = true}) async {
    debugPrint('AudioPlayerManager: Interrupting all audio${except != null ? ' except $except' : ''}');

    final futures = <Future>[];

    for (final entry in _sources.entries) {
      if (entry.key == except) {
        continue;
      }

      try {
        // Stop the player
        futures.add(entry.value.stop());

        // Clear position
        if (clearQueue) {
          futures.add(entry.value.seek(Duration.zero));
        }
      } catch (e) {
        debugPrint('AudioPlayerManager: Error stopping ${entry.key}: $e');
      }
    }

    await Future.wait(futures);

    // Update state
    if (_currentlyPlaying != except) {
      _currentlyPlaying = null;
      _playingStateController.add(false);
      _currentSourceController.add(null);
    }

    debugPrint('AudioPlayerManager: Interrupted ${futures.length ~/ (clearQueue ? 2 : 1)} players');
  }

  /// Stop a specific audio player by ID.
  Future<void> stop(String id) async {
    final player = _sources[id];
    if (player != null) {
      try {
        await player.stop();
        if (_currentlyPlaying == id) {
          _currentlyPlaying = null;
          _playingStateController.add(false);
          _currentSourceController.add(null);
        }
        debugPrint('AudioPlayerManager: Stopped player: $id');
      } catch (e) {
        debugPrint('AudioPlayerManager: Error stopping $id: $e');
      }
    }
  }

  /// Pause a specific audio player by ID.
  Future<void> pause(String id) async {
    final player = _sources[id];
    if (player != null) {
      try {
        await player.pause();
        debugPrint('AudioPlayerManager: Paused player: $id');
      } catch (e) {
        debugPrint('AudioPlayerManager: Error pausing $id: $e');
      }
    }
  }

  /// Resume a specific audio player by ID.
  Future<void> resume(String id) async {
    final player = _sources[id];
    if (player != null) {
      try {
        await player.play();
        debugPrint('AudioPlayerManager: Resumed player: $id');
      } catch (e) {
        debugPrint('AudioPlayerManager: Error resuming $id: $e');
      }
    }
  }

  /// Get a registered player by ID.
  AudioPlayer? getPlayer(String id) => _sources[id];

  /// Check if a specific player is registered.
  bool isRegistered(String id) => _sources.containsKey(id);

  /// Dispose all players and clean up.
  ///
  /// Call this when shutting down the app.
  Future<void> dispose() async {
    await interrupt();

    for (final player in _sources.values) {
      try {
        await player.dispose();
      } catch (e) {
        debugPrint('AudioPlayerManager: Error disposing player: $e');
      }
    }

    _sources.clear();
    _currentlyPlaying = null;

    await _playingStateController.close();
    await _currentSourceController.close();

    debugPrint('AudioPlayerManager: Disposed');
  }
}
