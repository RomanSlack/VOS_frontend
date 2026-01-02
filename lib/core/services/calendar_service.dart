import 'package:dio/dio.dart';
import 'package:vos_app/core/api/calendar_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/calendar_notification_service.dart';

class CalendarService {
  late final CalendarApi _api;
  late final CalendarToolHelper _toolHelper;
  late final CalendarNotificationService notificationService;
  final AuthService _authService = AuthService();

  CalendarService() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // JWT authentication only (no API key - security fix)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }

          // Add JWT token for authentication
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
    notificationService = CalendarNotificationService();
  }

  CalendarToolHelper get toolHelper => _toolHelper;

  void dispose() {
    notificationService.dispose();
  }
}
