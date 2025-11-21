import 'package:equatable/equatable.dart';

// ============================================================================
// Settings BLoC Events
// ============================================================================

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load settings from storage
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Update TTS provider selection
class UpdateTtsProvider extends SettingsEvent {
  final String provider;

  const UpdateTtsProvider(this.provider);

  @override
  List<Object?> get props => [provider];
}

/// Update voice selection
class UpdateVoiceId extends SettingsEvent {
  final String voiceId;

  const UpdateVoiceId(this.voiceId);

  @override
  List<Object?> get props => [voiceId];
}

/// Toggle custom voice mode
class ToggleCustomVoice extends SettingsEvent {
  final bool isCustom;

  const ToggleCustomVoice(this.isCustom);

  @override
  List<Object?> get props => [isCustom];
}

/// Update custom voice ID
class UpdateCustomVoiceId extends SettingsEvent {
  final String voiceId;

  const UpdateCustomVoiceId(this.voiceId);

  @override
  List<Object?> get props => [voiceId];
}

/// Save current settings
class SaveSettings extends SettingsEvent {
  const SaveSettings();
}

/// Reset settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
