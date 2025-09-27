import 'package:json_annotation/json_annotation.dart';

part 'weather_models.g.dart';

@JsonSerializable()
class WeatherResponseDto {
  final String location;
  final double temperature;
  final String description;
  final int humidity;
  @JsonKey(name: 'wind_speed')
  final double windSpeed;
  @JsonKey(name: 'feels_like')
  final double feelsLike;

  const WeatherResponseDto({
    required this.location,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
  });

  factory WeatherResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WeatherResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherResponseDtoToJson(this);
}

class WeatherData {
  final String location;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final DateTime lastUpdated;

  const WeatherData({
    required this.location,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.lastUpdated,
  });

  factory WeatherData.fromDto(WeatherResponseDto dto) {
    return WeatherData(
      location: dto.location,
      temperature: dto.temperature,
      description: dto.description,
      humidity: dto.humidity,
      windSpeed: dto.windSpeed,
      feelsLike: dto.feelsLike,
      lastUpdated: DateTime.now(),
    );
  }

  String get temperatureDisplay => '${temperature.round()}°F';
  String get feelsLikeDisplay => '${feelsLike.round()}°F';
  String get windSpeedDisplay => '${windSpeed.round()} mph';
  String get humidityDisplay => '$humidity%';
}