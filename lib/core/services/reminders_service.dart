import 'package:dio/dio.dart';
import 'package:vos_app/core/api/calendar_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';

class RemindersService {
  late final CalendarApi _api;
  late final CalendarToolHelper _toolHelper;
  final AuthService _authService = AuthService();

  RemindersService() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add authentication interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add API key
          options.headers['X-API-Key'] = AppConfig.apiKey;

          // Add JWT token if available
          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );

    _api = CalendarApi(dio);
    _toolHelper = CalendarToolHelper(_api);
  }

  CalendarToolHelper get toolHelper => _toolHelper;
}
