import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:provider/provider.dart';
import 'package:vos_app/core/router/app_routes.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/call_service.dart';
import 'package:vos_app/presentation/pages/home/home_page.dart';
import 'package:vos_app/presentation/pages/splash/splash_page.dart';
import 'package:vos_app/presentation/pages/login/login_page.dart';
import 'package:vos_app/features/voice/pages/voice_test_page.dart';
import 'package:vos_app/features/notes/pages/notes_page.dart';
import 'package:vos_app/features/settings/pages/settings_page.dart';
import 'package:vos_app/features/phone/pages/phone_page.dart';
import 'package:vos_app/features/phone/pages/active_call_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/features/notes/bloc/notes_bloc.dart';
import 'package:vos_app/features/notes/bloc/notes_event.dart';

@lazySingleton
class AppRouter {
  late final GoRouter _router;
  final AuthService _authService = AuthService();

  AppRouter() {
    _router = GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final isLoggedIn = await _authService.isLoggedIn();
        final isGoingToLogin = state.matchedLocation == AppRoutes.login;
        final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

        // Allow splash page always
        if (isGoingToSplash) return null;

        // If not logged in and not going to login, redirect to login
        if (!isLoggedIn && !isGoingToLogin) {
          return AppRoutes.login;
        }

        // If logged in and going to login, redirect to home
        if (isLoggedIn && isGoingToLogin) {
          return AppRoutes.home;
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.voiceTest,
          name: AppRoutes.voiceTest,
          builder: (context, state) => const VoiceTestPage(),
        ),
        GoRoute(
          path: AppRoutes.notes,
          name: AppRoutes.notes,
          builder: (context, state) => BlocProvider(
            create: (context) => getIt<NotesBloc>()..add(const LoadNotes()),
            child: const NotesPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.phone,
          name: AppRoutes.phone,
          builder: (context, state) => Provider<CallService>.value(
            value: getIt<CallService>(),
            child: const PhonePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.activeCall,
          name: AppRoutes.activeCall,
          builder: (context, state) => Provider<CallService>.value(
            value: getIt<CallService>(),
            child: const ActiveCallPage(),
          ),
        ),
      ],
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
    );
  }

  GoRouter get config => _router;

  void dispose() {
    _router.dispose();
  }
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}