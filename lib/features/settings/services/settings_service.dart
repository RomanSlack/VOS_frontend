import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

/// Service for persisting and loading application settings
class SettingsService {
  // Storage keys
  static const String _ttsProviderKey = 'tts_provider';
  static const String _ttsVoiceIdKey = 'tts_voice_id';
  static const String _isCustomVoiceKey = 'is_custom_voice';
  static const String _customVoiceIdKey = 'custom_voice_id';

  /// Load settings from persistent storage
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ttsProvider = prefs.getString(_ttsProviderKey);
      final ttsVoiceId = prefs.getString(_ttsVoiceIdKey);
      final isCustomVoice = prefs.getBool(_isCustomVoiceKey) ?? false;
      final customVoiceId = prefs.getString(_customVoiceIdKey);

      // If no settings saved, return defaults
      if (ttsProvider == null) {
        debugPrint('No saved settings found, using defaults');
        return AppSettings.defaults;
      }

      final settings = AppSettings(
        ttsProvider: ttsProvider,
        ttsVoiceId: ttsVoiceId,
        isCustomVoice: isCustomVoice,
        customVoiceId: customVoiceId,
      );

      debugPrint('Settings loaded: provider=$ttsProvider, voiceId=${settings.effectiveVoiceId}');
      return settings;
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return AppSettings.defaults;
    }
  }

  /// Save settings to persistent storage
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (settings.ttsProvider != null) {
        await prefs.setString(_ttsProviderKey, settings.ttsProvider!);
      } else {
        await prefs.remove(_ttsProviderKey);
      }

      if (settings.ttsVoiceId != null) {
        await prefs.setString(_ttsVoiceIdKey, settings.ttsVoiceId!);
      } else {
        await prefs.remove(_ttsVoiceIdKey);
      }

      await prefs.setBool(_isCustomVoiceKey, settings.isCustomVoice);

      if (settings.customVoiceId != null) {
        await prefs.setString(_customVoiceIdKey, settings.customVoiceId!);
      } else {
        await prefs.remove(_customVoiceIdKey);
      }

      debugPrint('Settings saved: provider=${settings.ttsProvider}, voiceId=${settings.effectiveVoiceId}');
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ttsProviderKey);
      await prefs.remove(_ttsVoiceIdKey);
      await prefs.remove(_isCustomVoiceKey);
      await prefs.remove(_customVoiceIdKey);
      debugPrint('Settings cleared');
    } catch (e) {
      debugPrint('Error clearing settings: $e');
      rethrow;
    }
  }

  /// Check if settings exist
  Future<bool> hasSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_ttsProviderKey);
    } catch (e) {
      return false;
    }
  }
}
