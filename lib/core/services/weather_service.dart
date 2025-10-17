import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/weather_api.dart';
import 'package:vos_app/core/models/weather_models.dart';

class WeatherService {
  late final WeatherApi _weatherApi;
  late final Dio _dio;

  static const String _apiKey = 'dev-key-12345';

  WeatherService() {
    _dio = Dio();

    // Add API key authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = _apiKey;
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

    _weatherApi = WeatherApi(_dio);
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
        throw Exception('Cannot connect to weather server. Please ensure the server is running on localhost:8000');
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