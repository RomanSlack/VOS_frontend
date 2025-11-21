import 'package:equatable/equatable.dart';

/// Application settings model
class AppSettings extends Equatable {
  /// TTS provider ID ('cartesia' or 'elevenlabs')
  final String? ttsProvider;

  /// Voice ID for the selected provider
  final String? ttsVoiceId;

  /// Whether using a custom voice ID (not from predefined list)
  final bool isCustomVoice;

  /// Custom voice ID input (when isCustomVoice is true)
  final String? customVoiceId;

  const AppSettings({
    this.ttsProvider,
    this.ttsVoiceId,
    this.isCustomVoice = false,
    this.customVoiceId,
  });

  /// Default settings
  static const AppSettings defaults = AppSettings(
    ttsProvider: 'cartesia',
    ttsVoiceId: '79a125e8-cd45-4c13-8a67-188112f4dd22', // British Lady
    isCustomVoice: false,
  );

  /// Get the effective voice ID (custom or selected)
  String? get effectiveVoiceId => isCustomVoice ? customVoiceId : ttsVoiceId;

  /// Create a copy with updated values
  AppSettings copyWith({
    String? ttsProvider,
    String? ttsVoiceId,
    bool? isCustomVoice,
    String? customVoiceId,
  }) {
    return AppSettings(
      ttsProvider: ttsProvider ?? this.ttsProvider,
      ttsVoiceId: ttsVoiceId ?? this.ttsVoiceId,
      isCustomVoice: isCustomVoice ?? this.isCustomVoice,
      customVoiceId: customVoiceId ?? this.customVoiceId,
    );
  }

  @override
  List<Object?> get props => [ttsProvider, ttsVoiceId, isCustomVoice, customVoiceId];
}

/// Device and session information model
class DeviceInfo extends Equatable {
  final String? sessionId;
  final String? username;
  final bool isConnected;
  final String deviceType;
  final String appVersion;
  final String? currentTtsProvider;
  final String? currentTtsVoiceId;

  const DeviceInfo({
    this.sessionId,
    this.username,
    this.isConnected = false,
    required this.deviceType,
    required this.appVersion,
    this.currentTtsProvider,
    this.currentTtsVoiceId,
  });

  /// Default device info
  static const DeviceInfo empty = DeviceInfo(
    deviceType: 'unknown',
    appVersion: '1.0.0',
  );

  /// Create a copy with updated values
  DeviceInfo copyWith({
    String? sessionId,
    String? username,
    bool? isConnected,
    String? deviceType,
    String? appVersion,
    String? currentTtsProvider,
    String? currentTtsVoiceId,
  }) {
    return DeviceInfo(
      sessionId: sessionId ?? this.sessionId,
      username: username ?? this.username,
      isConnected: isConnected ?? this.isConnected,
      deviceType: deviceType ?? this.deviceType,
      appVersion: appVersion ?? this.appVersion,
      currentTtsProvider: currentTtsProvider ?? this.currentTtsProvider,
      currentTtsVoiceId: currentTtsVoiceId ?? this.currentTtsVoiceId,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        username,
        isConnected,
        deviceType,
        appVersion,
        currentTtsProvider,
        currentTtsVoiceId,
      ];
}
