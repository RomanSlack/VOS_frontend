import 'package:flutter/material.dart';
import 'package:vos_app/core/themes/app_theme.dart';
import 'package:vos_app/presentation/pages/home/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOS App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}