import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:vos_app/core/di/injection.config.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/services/weather_service.dart';
import 'package:vos_app/core/services/voice_service.dart';
import 'package:vos_app/core/services/calendar_service.dart';
import 'package:vos_app/core/services/reminders_service.dart';
import 'package:vos_app/core/managers/voice_manager.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/reminders/bloc/reminders_bloc.dart';

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
  getIt.registerLazySingleton<CalendarService>(() => CalendarService());
  getIt.registerLazySingleton<RemindersService>(() => RemindersService());

  // Register voice manager (depends on VoiceService)
  getIt.registerLazySingleton<VoiceManager>(
    () => VoiceManager(getIt<VoiceService>()),
  );

  // Register BLoCs
  getIt.registerFactory<CalendarBloc>(
    () => CalendarBloc(getIt<CalendarService>().toolHelper),
  );
  getIt.registerFactory<RemindersBloc>(
    () => RemindersBloc(getIt<RemindersService>().toolHelper),
  );

  getIt.init();
}