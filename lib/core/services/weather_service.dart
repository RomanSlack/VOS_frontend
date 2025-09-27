import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/weather_api.dart';
import 'package:vos_app/core/models/weather_models.dart';

class WeatherService {
  late final WeatherApi _weatherApi;
  late final Dio _dio;

  WeatherService() {
    _dio = Dio();

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

  Future<WeatherData> getCurrentWeather() async {
    try {
      final response = await _weatherApi.getRochesterWeather();
      return WeatherData.fromDto(response);

    } on DioException catch (e) {
      debugPrint('Weather API Error: ${e.message}');
      if (e.response?.statusCode == 503) {
        throw Exception('Weather service is temporarily unavailable. Please try again later.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please check if the weather service is running properly.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to weather server. Please ensure the server is running on localhost:5555');
      }
      throw Exception('Weather request failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}