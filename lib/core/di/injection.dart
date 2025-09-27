import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:vos_app/core/di/injection.config.dart';
import 'package:vos_app/core/services/chat_service.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Register ChatService manually since it's not using injectable
  getIt.registerLazySingleton<ChatService>(() => ChatService());

  getIt.init();
}