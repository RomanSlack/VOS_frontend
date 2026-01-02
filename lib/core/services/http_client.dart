import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';

/// Authenticated HTTP client that uses JWT tokens for all requests.
/// This is the ONLY way services should make authenticated API calls.
class AuthenticatedClient {
  static final AuthenticatedClient _instance = AuthenticatedClient._internal();
  factory AuthenticatedClient() => _instance;

  late final Dio _dio;
  final AuthService _authService = AuthService();

  AuthenticatedClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add JWT authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get JWT token from auth service
          final token = await _authService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // For Android emulator, override Host header to localhost
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - token expired or invalid
          if (error.response?.statusCode == 401) {
            debugPrint('⚠️ Unauthorized request - token may be expired');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get the configured Dio instance with JWT auth
  Dio get dio => _dio;

  /// Create a new Dio instance with JWT auth for services that need custom config
  static Dio createDio({
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    final authService = AuthService();

    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }

          return handler.next(options);
        },
      ),
    );

    return dio;
  }
}
