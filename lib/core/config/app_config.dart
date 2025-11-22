import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from environment files
class AppConfig {
  static late String apiBaseUrl;
  static late String voiceApiBaseUrl;
  static late String wsBaseUrl;
  static late String voiceWsBaseUrl;
  static late String apiKey;
  static late bool enableAnalytics;
  static late bool enableCrashlytics;
  static late bool enablePerformance;
  static late String appName;
  static late String appVersion;
  static late String supportEmail;

  /// Initialize configuration from .env files
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ Loaded .env configuration');
    } catch (e) {
      print('⚠️ Failed to load .env file: $e');
      print('⚠️ Using default configuration values (localhost)');
      // Initialize dotenv.env as empty map so we can use defaults
      dotenv.env.clear();
    }

    // API Configuration with platform-specific handling
    String envApiUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.jarvos.dev';
    String envVoiceUrl = dotenv.env['VOICE_API_BASE_URL'] ?? envApiUrl;

    // Convert localhost to 10.0.2.2 for Android emulator
    apiBaseUrl = _convertLocalhostForPlatform(envApiUrl);
    voiceApiBaseUrl = _convertLocalhostForPlatform(envVoiceUrl);
    wsBaseUrl = dotenv.env['WS_BASE_URL'] ?? _deriveWsUrl(apiBaseUrl);
    voiceWsBaseUrl = dotenv.env['VOICE_WS_BASE_URL'] ?? _deriveWsUrl(voiceApiBaseUrl);
    apiKey = dotenv.env['API_KEY'] ?? 'dev-key-12345';

    // Feature Flags
    enableAnalytics = dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';
    enableCrashlytics = dotenv.env['ENABLE_CRASHLYTICS']?.toLowerCase() == 'true';
    enablePerformance = dotenv.env['ENABLE_PERFORMANCE']?.toLowerCase() == 'true';

    // App Configuration
    appName = dotenv.env['APP_NAME'] ?? 'VOS App';
    appVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
    supportEmail = dotenv.env['SUPPORT_EMAIL'] ?? 'support@vosapp.com';

    print('🔧 AppConfig initialized:');
    print('  API Base URL: $apiBaseUrl');
    print('  Voice API Base URL: $voiceApiBaseUrl');
    print('  WS Base URL: $wsBaseUrl');
    print('  Voice WS Base URL: $voiceWsBaseUrl');
    print('  Production Mode: $isProduction');
  }

  /// Convert localhost URLs to platform-specific addresses
  /// - Web: keeps localhost as-is
  /// - Android: converts localhost to 10.0.2.2 (emulator host mapping)
  /// - iOS/others: keeps localhost as-is
  static String _convertLocalhostForPlatform(String url) {
    if (kIsWeb) {
      // Web: use localhost as-is
      return url;
    }

    // Check if running on Android (not web)
    try {
      if (Platform.isAndroid) {
        // Android emulator: map localhost to host machine
        return url
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2');
      }
    } catch (e) {
      // If Platform is not available (shouldn't happen), return as-is
    }

    return url;
  }

  /// Derive WebSocket URL from HTTP API URL
  /// Converts http:// to ws:// and https:// to wss://
  static String _deriveWsUrl(String apiUrl) {
    if (apiUrl.startsWith('https://')) {
      return apiUrl.replaceFirst('https://', 'wss://');
    } else if (apiUrl.startsWith('http://')) {
      return apiUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://$apiUrl';
  }

  /// Check if running in production mode (using https/wss)
  static bool get isProduction => apiBaseUrl.startsWith('https://');

  /// Get the full WebSocket URL for conversations
  static String getWebSocketUrl(String sessionId, String token) {
    return '$wsBaseUrl/api/v1/ws/conversations/$sessionId/stream?token=$token';
  }

  /// Get the full WebSocket URL for voice mode
  static String getVoiceWebSocketUrl(String sessionId) {
    return '$voiceWsBaseUrl/ws/voice/$sessionId';
  }
}
