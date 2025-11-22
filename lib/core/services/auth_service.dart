import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vos_app/core/config/app_config.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _expiryKey = 'token_expiry';
  static const String _usernameKey = 'username';
  static const String _rememberMeKey = 'remember_me';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // Add API key authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = AppConfig.apiKey;
          // For Android emulator, override Host header to localhost
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }
          return handler.next(options);
        },
      ),
    );
  }

  final Dio _dio = Dio();
  String? _cachedToken;

  /// Login and get JWT token
  Future<String> login(String username, String password, {bool rememberMe = true}) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/v1/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'] as String;
        final expiresIn = response.data['expires_in'] as int; // seconds

        // Calculate expiry timestamp
        final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

        // Save token and expiry
        await _saveToken(token, username, expiryTime, rememberMe);
        _cachedToken = token;

        debugPrint('✅ Login successful for user: $username (Remember: $rememberMe)');
        debugPrint('Token expires at: $expiryTime');
        return token;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint('Login error: ${e.message}');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Request data: ${e.requestOptions.data}');
      debugPrint('Request headers: ${e.requestOptions.headers}');

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      } else if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data.toString() ?? 'Bad request';
        throw Exception('Login failed: $errorMsg');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server at ${AppConfig.apiBaseUrl}');
      }

      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    // Always return cached token if available (for non-remember-me sessions)
    if (_cachedToken != null) {
      final isExpired = await isTokenExpired();
      if (isExpired) {
        debugPrint('⚠️ Token expired, logging out');
        await logout();
        return null;
      }
      return _cachedToken;
    }

    // Check if user enabled remember me
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (!rememberMe) {
      // Don't load from storage
      return null;
    }

    // Load from storage
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

    final isExpired = await isTokenExpired();
    if (isExpired) {
      debugPrint('⚠️ Token expired, logging out');
      await logout();
      return null;
    }

    _cachedToken = token;
    return _cachedToken;
  }

  /// Get stored username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_expiryKey);

    if (expiryString == null) return true;

    final expiryTime = DateTime.parse(expiryString);
    final now = DateTime.now();

    return now.isAfter(expiryTime);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout and clear stored token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_expiryKey);
    _cachedToken = null;
    debugPrint('✅ Logged out successfully');
  }

  /// Save token to persistent storage
  Future<void> _saveToken(String token, String username, DateTime expiryTime, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    // Always cache in memory
    _cachedToken = token;

    if (rememberMe) {
      // Save permanently to storage
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_expiryKey, expiryTime.toIso8601String());
      await prefs.setBool(_rememberMeKey, true);
    } else {
      // For session-only login, save expiry but not token
      await prefs.setString(_expiryKey, expiryTime.toIso8601String());
      await prefs.setBool(_rememberMeKey, false);
      // Clear any previously saved token
      await prefs.remove(_tokenKey);
      await prefs.remove(_usernameKey);
    }
  }
}
