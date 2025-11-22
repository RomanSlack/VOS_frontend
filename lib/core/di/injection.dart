import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:vos_app/core/di/injection.config.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/services/weather_service.dart';
import 'package:vos_app/core/services/voice_service.dart';
import 'package:vos_app/core/services/voice_batch_service.dart';
import 'package:vos_app/core/services/calendar_service.dart';
import 'package:vos_app/core/services/notes_service.dart';
import 'package:vos_app/core/managers/voice_manager.dart';
import 'package:vos_app/core/api/memory_api.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/notes/bloc/notes_bloc.dart';
import 'package:vos_app/features/settings/bloc/settings_bloc.dart';
import 'package:vos_app/features/settings/services/settings_service.dart';
import 'package:vos_app/features/memory_visualization/bloc/memory_viz_bloc.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/config/app_config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Register services manually since they're not using injectable
  getIt.registerLazySingleton<ChatService>(() => ChatService());
  getIt.registerLazySingleton<WeatherService>(() => WeatherService());
  getIt.registerLazySingleton<VoiceService>(() => VoiceService());
  getIt.registerLazySingleton<VoiceBatchService>(() => VoiceBatchService());
  getIt.registerLazySingleton<CalendarService>(() => CalendarService());
  getIt.registerLazySingleton<NotesService>(() => NotesService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());

  // Register voice manager (depends on VoiceService, VoiceBatchService, and SettingsService)
  getIt.registerLazySingleton<VoiceManager>(
    () => VoiceManager(
      getIt<VoiceService>(),
      getIt<VoiceBatchService>(),
      getIt<SettingsService>(),
    ),
  );

  // Register BLoCs
  getIt.registerFactory<CalendarBloc>(
    () => CalendarBloc(getIt<CalendarService>().toolHelper),
  );
  getIt.registerFactory<NotesBloc>(
    () => NotesBloc(
      getIt<NotesService>().toolHelper,
      'user_session_default', // TODO: Get actual user ID from auth context
    ),
  );
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      settingsService: getIt<SettingsService>(),
      voiceManager: getIt<VoiceManager>(),
      voiceService: getIt<VoiceService>(),
      authService: getIt<AuthService>(),
    ),
  );

  // Register Memory API with authentication
  final memoryDio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Add authentication interceptor
  memoryDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add API key
        options.headers['X-API-Key'] = AppConfig.apiKey;

        // Add JWT token if available
        final token = await getIt<AuthService>().getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
    ),
  );

  getIt.registerLazySingleton<MemoryApi>(
    () => MemoryApi(memoryDio),
  );

  // Register Memory Visualization BLoC
  getIt.registerFactory<MemoryVizBloc>(
    () => MemoryVizBloc(getIt<MemoryApi>()),
  );

  getIt.init();
}