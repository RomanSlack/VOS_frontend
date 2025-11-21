import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vos_app/core/managers/voice_manager.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/voice_service.dart';
import 'package:vos_app/features/settings/bloc/settings_event.dart';
import 'package:vos_app/features/settings/bloc/settings_state.dart';
import 'package:vos_app/features/settings/models/settings_model.dart';
import 'package:vos_app/features/settings/services/settings_service.dart';
import 'package:vos_app/features/settings/data/voice_options.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;
  final VoiceManager _voiceManager;
  final VoiceService _voiceService;
  final AuthService _authService;

  SettingsBloc({
    required SettingsService settingsService,
    required VoiceManager voiceManager,
    required VoiceService voiceService,
    required AuthService authService,
  })  : _settingsService = settingsService,
        _voiceManager = voiceManager,
        _voiceService = voiceService,
        _authService = authService,
        super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTtsProvider>(_onUpdateTtsProvider);
    on<UpdateVoiceId>(_onUpdateVoiceId);
    on<ToggleCustomVoice>(_onToggleCustomVoice);
    on<UpdateCustomVoiceId>(_onUpdateCustomVoiceId);
    on<SaveSettings>(_onSaveSettings);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());

      // Load settings from storage
      final settings = await _settingsService.loadSettings();

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      emit(SettingsLoaded(
        settings: settings,
        deviceInfo: deviceInfo,
      ));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onUpdateTtsProvider(
    UpdateTtsProvider event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Get default voice for the new provider
    final defaultVoice = VoiceOptions.getDefaultVoice(event.provider);
    final newVoiceId = defaultVoice?.id;

    final updatedSettings = currentState.settings.copyWith(
      ttsProvider: event.provider,
      ttsVoiceId: newVoiceId,
      isCustomVoice: false, // Reset to predefined voices
      customVoiceId: null,
    );

    emit(currentState.copyWith(settings: updatedSettings));
  }

  Future<void> _onUpdateVoiceId(
    UpdateVoiceId event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      ttsVoiceId: event.voiceId,
    );

    emit(currentState.copyWith(settings: updatedSettings));
  }

  Future<void> _onToggleCustomVoice(
    ToggleCustomVoice event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      isCustomVoice: event.isCustom,
    );

    emit(currentState.copyWith(settings: updatedSettings));
  }

  Future<void> _onUpdateCustomVoiceId(
    UpdateCustomVoiceId event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      customVoiceId: event.voiceId,
    );

    emit(currentState.copyWith(settings: updatedSettings));
  }

  Future<void> _onSaveSettings(
    SaveSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      emit(SettingsSaving(
        settings: currentState.settings,
        deviceInfo: currentState.deviceInfo,
      ));

      // Save settings to storage
      await _settingsService.saveSettings(currentState.settings);

      // Check if we need to reconnect
      final wasConnected = _voiceManager.isConnected;
      final sessionId = _voiceManager.sessionId;

      if (wasConnected && sessionId != null) {
        // Configure TTS with new settings
        _voiceService.configureTts(
          provider: currentState.settings.ttsProvider,
          voiceId: currentState.settings.effectiveVoiceId,
        );

        // Disconnect and reconnect with new settings
        await _voiceManager.disconnect();
        await _voiceManager.connect(sessionId);

        debugPrint('Reconnected with new TTS settings');
      }

      // Update device info with current TTS config
      final updatedDeviceInfo = currentState.deviceInfo.copyWith(
        currentTtsProvider: currentState.settings.ttsProvider,
        currentTtsVoiceId: currentState.settings.effectiveVoiceId,
      );

      emit(SettingsSaved(
        settings: currentState.settings,
        deviceInfo: updatedDeviceInfo,
        requiresReconnect: wasConnected,
      ));

      // Return to loaded state after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(SettingsLoaded(
        settings: currentState.settings,
        deviceInfo: updatedDeviceInfo,
      ));
    } catch (e) {
      emit(SettingsError(
        'Failed to save settings: $e',
        settings: currentState.settings,
        deviceInfo: currentState.deviceInfo,
      ));
    }
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      // Clear saved settings
      await _settingsService.clearSettings();

      // Reset to defaults
      emit(currentState.copyWith(settings: AppSettings.defaults));
    } catch (e) {
      emit(SettingsError(
        'Failed to reset settings: $e',
        settings: currentState.settings,
        deviceInfo: currentState.deviceInfo,
      ));
    }
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    // Get app version
    String appVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('Failed to get package info: $e');
    }

    // Determine device type
    String deviceType = 'unknown';
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceType = 'mobile';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      deviceType = 'desktop';
    }

    // Get username
    final username = await _authService.getUsername();

    return DeviceInfo(
      sessionId: _voiceManager.sessionId,
      username: username,
      isConnected: _voiceManager.isConnected,
      deviceType: deviceType,
      appVersion: appVersion,
      currentTtsProvider: _voiceService.ttsProvider,
      currentTtsVoiceId: _voiceService.ttsVoiceId,
    );
  }
}
