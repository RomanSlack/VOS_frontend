import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/weather_models.dart';

part 'weather_api.g.dart';

@RestApi(baseUrl: 'http://localhost:8000')
abstract class WeatherApi {
  factory WeatherApi(Dio dio) = _WeatherApi;

  @GET('/api/v1/weather/current')
  Future<WeatherResponseDto> getCurrentWeather({
    @Query('location') required String location,
    @Query('units') String units = 'metric',
  });
}