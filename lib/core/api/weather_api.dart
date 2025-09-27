import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/weather_models.dart';

part 'weather_api.g.dart';

@RestApi(baseUrl: 'http://localhost:5555')
abstract class WeatherApi {
  factory WeatherApi(Dio dio) = _WeatherApi;

  @GET('/weather/rochester')
  Future<WeatherResponseDto> getRochesterWeather();
}