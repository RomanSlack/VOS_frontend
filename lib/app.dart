import 'package:flutter/material.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/router/app_router.dart';
import 'package:vos_app/core/themes/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      title: 'VOS App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config,
    );
  }
}