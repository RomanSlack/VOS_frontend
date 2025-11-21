import 'package:equatable/equatable.dart';
import '../models/settings_model.dart';

// ============================================================================
// Settings States
// ============================================================================

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before settings are loaded
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading settings from storage
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings loaded and available
class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  final DeviceInfo deviceInfo;

  const SettingsLoaded({
    required this.settings,
    required this.deviceInfo,
  });

  @override
  List<Object?> get props => [settings, deviceInfo];

  SettingsLoaded copyWith({
    AppSettings? settings,
    DeviceInfo? deviceInfo,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

/// Settings are being saved
class SettingsSaving extends SettingsState {
  final AppSettings settings;
  final DeviceInfo deviceInfo;

  const SettingsSaving({
    required this.settings,
    required this.deviceInfo,
  });

  @override
  List<Object?> get props => [settings, deviceInfo];
}

/// Settings saved successfully
class SettingsSaved extends SettingsState {
  final AppSettings settings;
  final DeviceInfo deviceInfo;
  final bool requiresReconnect;

  const SettingsSaved({
    required this.settings,
    required this.deviceInfo,
    this.requiresReconnect = false,
  });

  @override
  List<Object?> get props => [settings, deviceInfo, requiresReconnect];
}

/// Error state
class SettingsError extends SettingsState {
  final String message;
  final AppSettings? settings;
  final DeviceInfo? deviceInfo;

  const SettingsError(
    this.message, {
    this.settings,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [message, settings, deviceInfo];
}
