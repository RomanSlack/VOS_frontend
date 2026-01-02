import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/weather_api.dart';
import 'package:vos_app/core/models/weather_models.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';

class WeatherService {
  late final WeatherApi _weatherApi;
  late final Dio _dio;

  WeatherService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ));

    // JWT authentication only (no API key - security fix)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }
          // Add JWT token for authentication
          final authService = AuthService();
          final token = await authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    _weatherApi = WeatherApi(_dio, baseUrl: AppConfig.apiBaseUrl);
  }

  /// Search for weather by city name
  Future<WeatherData> searchWeather(String cityName) async {
    if (cityName.trim().isEmpty) {
      throw Exception('Please enter a city name');
    }

    try {
      final response = await _weatherApi.getCurrentWeather(
        location: cityName.trim(),
        units: 'metric',
      );
      return WeatherData.fromDto(response);

    } on DioException catch (e) {
      debugPrint('Weather API Error: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('City not found. Try another search!');
      } else if (e.response?.statusCode == 503) {
        throw Exception('Weather service is temporarily unavailable. Please try again later.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please check if the weather service is running properly.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to weather server at ${AppConfig.apiBaseUrl}');
      }
      throw Exception('Unable to fetch weather. Please try again.');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get default weather (for initial load, optional)
  Future<WeatherData> getDefaultWeather() async {
    return searchWeather('San Francisco');
  }
}