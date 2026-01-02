import 'package:dio/dio.dart';
import 'package:vos_app/core/api/notes_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/services/auth_service.dart';

class NotesService {
  late final NotesApi _api;
  late final NotesToolHelper _toolHelper;
  final AuthService _authService = AuthService();

  NotesService() {
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

    _api = NotesApi(dio);
    _toolHelper = NotesToolHelper(_api);
  }

  NotesToolHelper get toolHelper => _toolHelper;
}
