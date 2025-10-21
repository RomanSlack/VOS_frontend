import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vos_app/core/services/weather_service.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/models/weather_models.dart';

class WeatherApp extends StatefulWidget {
  final WeatherService weatherService;
  final ChatService? chatService;

  const WeatherApp({
    super.key,
    required this.weatherService,
    this.chatService,
  });

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final TextEditingController _searchController = TextEditingController();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _appInteractionSubscription;

  @override
  void initState() {
    super.initState();
    _loadDefaultWeather();
    _subscribeToWebSocketUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _appInteractionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToWebSocketUpdates() {
    // Listen for weather agent updates via WebSocket
    if (widget.chatService == null) return;

    _appInteractionSubscription = widget.chatService!.appInteractionStream.listen(
      (payload) {
        if (payload.appName == 'weather_app' && payload.action == 'weather_data_fetched') {
          try {
            final weatherDto = WeatherResponseDto.fromJson(payload.result);
            setState(() {
              _weatherData = WeatherData.fromDto(weatherDto);
              _errorMessage = null;
            });
            debugPrint('📱 Received weather update from agent');
          } catch (e) {
            debugPrint('Error parsing agent weather data: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Error in app interaction stream: $error');
      },
    );
  }

  Future<void> _loadDefaultWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await widget.weatherService.getDefaultWeather();
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchWeather() async {
    final cityName = _searchController.text.trim();
    if (cityName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await widget.weatherService.searchWeather(cityName);
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          // Header with search bar
          _buildHeader(),

          // Weather content
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? _buildError()
                    : _weatherData != null
                        ? _buildWeatherContent()
                        : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search,
                    color: Color(0xFF757575),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search for a city...',
                        hintStyle: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _searchWeather(),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      color: const Color(0xFF00BCD4),
                      iconSize: 20,
                      onPressed: _searchWeather,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF00BCD4),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFFF5252),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDefaultWeather,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Search for a city to see weather',
        style: TextStyle(
          color: Color(0xFF757575),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final weather = _weatherData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header: Location + Temp + Emoji
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.locationDisplay,
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.temperatureDisplay,
                          style: const TextStyle(
                            color: Color(0xFFEDEDED),
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.feelsLikeDisplay,
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      weather.tempRangeDisplay,
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    weather.condition.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  Text(
                    weather.condition.description,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details grid
          _buildDetailsGrid(weather),

          const SizedBox(height: 12),

          // Last updated
          Text(
            'Last updated: ${_formatTime(weather.lastUpdated)}',
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(WeatherData weather) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.water_drop,
                  'Humidity',
                  weather.atmosphere.humidity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  Icons.air,
                  'Wind',
                  '${weather.wind.speed} ${weather.wind.directionText}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.speed,
                  'Pressure',
                  weather.atmosphere.pressure,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailItem(
                  Icons.visibility,
                  'Visibility',
                  weather.visibility,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.cloud,
                  'Cloudiness',
                  weather.cloudiness,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSunriseSunsetItem(weather.sunrise, weather.sunset),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetItem(String sunrise, String sunset) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_twilight,
                size: 14,
                color: Color(0xFF00BCD4),
              ),
              const SizedBox(width: 4),
              const Text(
                'Sunrise/Sunset',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$sunrise / $sunset',
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
