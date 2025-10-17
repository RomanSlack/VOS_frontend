import 'package:json_annotation/json_annotation.dart';

part 'weather_models.g.dart';

// Comprehensive Weather Models for New API

@JsonSerializable()
class TemperatureData {
  final double current;
  @JsonKey(name: 'feels_like')
  final double feelsLike;
  final double min;
  final double max;
  final String unit;

  const TemperatureData({
    required this.current,
    required this.feelsLike,
    required this.min,
    required this.max,
    required this.unit,
  });

  factory TemperatureData.fromJson(Map<String, dynamic> json) =>
      _$TemperatureDataFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureDataToJson(this);
}

@JsonSerializable()
class WeatherCondition {
  final String main;
  final String description;
  final String icon;

  const WeatherCondition({
    required this.main,
    required this.description,
    required this.icon,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) =>
      _$WeatherConditionFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherConditionToJson(this);

  // Get emoji for weather condition
  String get emoji {
    switch (main.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return icon.contains('02') ? '⛅' : '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}

@JsonSerializable()
class AtmosphereData {
  final String humidity;
  final String pressure;

  const AtmosphereData({
    required this.humidity,
    required this.pressure,
  });

  factory AtmosphereData.fromJson(Map<String, dynamic> json) =>
      _$AtmosphereDataFromJson(json);

  Map<String, dynamic> toJson() => _$AtmosphereDataToJson(this);
}

@JsonSerializable()
class WindData {
  final String speed;
  final int direction;

  const WindData({
    required this.speed,
    required this.direction,
  });

  factory WindData.fromJson(Map<String, dynamic> json) =>
      _$WindDataFromJson(json);

  Map<String, dynamic> toJson() => _$WindDataToJson(this);

  // Get wind direction as text
  String get directionText {
    if (direction >= 337.5 || direction < 22.5) return 'N';
    if (direction >= 22.5 && direction < 67.5) return 'NE';
    if (direction >= 67.5 && direction < 112.5) return 'E';
    if (direction >= 112.5 && direction < 157.5) return 'SE';
    if (direction >= 157.5 && direction < 202.5) return 'S';
    if (direction >= 202.5 && direction < 247.5) return 'SW';
    if (direction >= 247.5 && direction < 292.5) return 'W';
    return 'NW';
  }
}

@JsonSerializable()
class WeatherResponseDto {
  final String location;
  final String country;
  final TemperatureData temperature;
  final WeatherCondition condition;
  final AtmosphereData atmosphere;
  final WindData wind;
  final String visibility;
  final String cloudiness;
  final String sunrise;
  final String sunset;

  const WeatherResponseDto({
    required this.location,
    required this.country,
    required this.temperature,
    required this.condition,
    required this.atmosphere,
    required this.wind,
    required this.visibility,
    required this.cloudiness,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WeatherResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherResponseDtoToJson(this);
}

// App Interaction Notification Payload
@JsonSerializable()
class AppInteractionPayload {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'app_name')
  final String appName;
  final String action;
  final Map<String, dynamic> result;

  const AppInteractionPayload({
    required this.agentId,
    required this.appName,
    required this.action,
    required this.result,
  });

  factory AppInteractionPayload.fromJson(Map<String, dynamic> json) =>
      _$AppInteractionPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AppInteractionPayloadToJson(this);
}

// UI-friendly Weather Data
class WeatherData {
  final String location;
  final String country;
  final TemperatureData temperature;
  final WeatherCondition condition;
  final AtmosphereData atmosphere;
  final WindData wind;
  final String visibility;
  final String cloudiness;
  final String sunrise;
  final String sunset;
  final DateTime lastUpdated;

  const WeatherData({
    required this.location,
    required this.country,
    required this.temperature,
    required this.condition,
    required this.atmosphere,
    required this.wind,
    required this.visibility,
    required this.cloudiness,
    required this.sunrise,
    required this.sunset,
    required this.lastUpdated,
  });

  factory WeatherData.fromDto(WeatherResponseDto dto) {
    return WeatherData(
      location: dto.location,
      country: dto.country,
      temperature: dto.temperature,
      condition: dto.condition,
      atmosphere: dto.atmosphere,
      wind: dto.wind,
      visibility: dto.visibility,
      cloudiness: dto.cloudiness,
      sunrise: dto.sunrise,
      sunset: dto.sunset,
      lastUpdated: DateTime.now(),
    );
  }

  String get locationDisplay => '$location, $country';
  String get temperatureDisplay => '${temperature.current.round()}${temperature.unit}';
  String get feelsLikeDisplay => 'Feels like ${temperature.feelsLike.round()}${temperature.unit}';
  String get tempRangeDisplay => '${temperature.min.round()}° / ${temperature.max.round()}°';
}
