import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/notification_toast.dart';
import 'package:vos_app/presentation/pages/home/desktop_home_page.dart';
import 'package:vos_app/presentation/pages/home/mobile_home_page.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/sticky_notes_manager.dart';
import 'package:vos_app/core/services/calendar_service.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/utils/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VosModalManager? _modalManager;
  final StickyNotesManager _stickyNotesManager = StickyNotesManager();

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure GetIt is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _modalManager = VosModalManager();
      });
      _initializeNotifications();
      // Subscribe sticky notes manager to WebSocket for real-time updates
      final chatService = getIt<ChatService>();
      _stickyNotesManager.subscribeToWebSocket(chatService);
    });
  }

  void _initializeNotifications() {
    final calendarService = getIt<CalendarService>();
    final notificationService = calendarService.notificationService;

    // Connect to WebSocket
    notificationService.connect().then((_) {
      logger.i('HomePage: Calendar notification service connected');
    }).catchError((error) {
      logger.e('HomePage: Failed to connect notification service: $error');
    });
  }

  @override
  void dispose() {
    _modalManager?.dispose();
    _stickyNotesManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while modal manager is initializing
    if (_modalManager == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF212121),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00BCD4),
          ),
        ),
      );
    }

    // Detect screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900; // Breakpoint for mobile/tablet

    // Route to appropriate layout
    return isMobile
        ? MobileHomePage(
            modalManager: _modalManager!,
            stickyNotesManager: _stickyNotesManager,
          )
        : DesktopHomePage(
            modalManager: _modalManager!,
            stickyNotesManager: _stickyNotesManager,
          );
  }
}