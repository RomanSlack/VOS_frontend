import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/vos_modal.dart';
import 'package:vos_app/presentation/widgets/chat_app.dart';
import 'package:vos_app/presentation/widgets/calendar_app.dart';
import 'package:vos_app/presentation/widgets/notes_app.dart';
import 'package:vos_app/presentation/widgets/weather_app.dart';
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/services/weather_service.dart';
import 'package:vos_app/core/di/injection.dart';

// App definitions for each modal
class AppDefinition {
  final String id;
  final String title;
  final IconData icon;
  final Color? accentColor;
  final Widget Function() contentBuilder;

  const AppDefinition({
    required this.id,
    required this.title,
    required this.icon,
    this.accentColor,
    required this.contentBuilder,
  });
}

// Modal state for tracking
class ModalInstance {
  final String appId;
  final VosModal modal;
  final ValueNotifier<ModalState> stateNotifier;
  final DateTime openedAt;

  ModalInstance({
    required this.appId,
    required this.modal,
    required this.stateNotifier,
    required this.openedAt,
  });

  ModalState get state => stateNotifier.value;
  set state(ModalState newState) {
    stateNotifier.value = newState;
  }
}

class VosModalManager extends ChangeNotifier {
  static const int maxModals = 4;
  static const String defaultSessionId = 'user_session_default';

  final Map<String, ModalInstance> _openModals = {};
  final Map<String, ModalInstance> _minimizedModals = {};
  bool _showLimitNotification = false;
  late final ChatManager _chatManager;
  late final ChatService _chatService;
  late final WeatherService _weatherService;
  final ValueNotifier<String?> _chatStatusNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _chatIsActiveNotifier = ValueNotifier<bool>(true);

  // Cache for performance
  List<ModalInstance>? _openModalsCache;
  List<ModalInstance>? _minimizedModalsCache;
  bool _cacheValid = false;

  // Getters with caching
  List<ModalInstance> get openModals {
    if (!_cacheValid || _openModalsCache == null) {
      _openModalsCache = _openModals.values.toList();
    }
    return _openModalsCache!;
  }

  List<ModalInstance> get minimizedModals {
    if (!_cacheValid || _minimizedModalsCache == null) {
      _minimizedModalsCache = _minimizedModals.values.toList();
    }
    return _minimizedModalsCache!;
  }

  bool get showLimitNotification => _showLimitNotification;
  int get openModalCount => _openModals.length + _minimizedModals.length;
  bool get canOpenMore => openModalCount < maxModals;
  ChatManager get chatManager => _chatManager;

  VosModalManager() {
    _chatManager = ChatManager();
    _chatService = getIt<ChatService>();
    _weatherService = getIt<WeatherService>();
  }

  void _invalidateCache() {
    _cacheValid = false;
    _openModalsCache = null;
    _minimizedModalsCache = null;
  }

  // App definitions
  static const List<AppDefinition> apps = [
    AppDefinition(
      id: 'phone',
      title: 'Phone',
      icon: Icons.phone_outlined,
      accentColor: Color(0xFF4CAF50),
      contentBuilder: _buildPhoneContent,
    ),
    // Note: Calendar app is handled specially - see openModal method
    AppDefinition(
      id: 'tasks',
      title: 'Tasks',
      icon: Icons.check_circle_outline,
      accentColor: Color(0xFF9C27B0),
      contentBuilder: _buildTasksContent,
    ),
    AppDefinition(
      id: 'browser',
      title: 'Browser',
      icon: Icons.language_outlined,
      accentColor: Color(0xFFFF5722),
      contentBuilder: _buildBrowserContent,
    ),
    AppDefinition(
      id: 'analytics',
      title: 'Analytics',
      icon: Icons.bar_chart_outlined,
      accentColor: Color(0xFF607D8B),
      contentBuilder: _buildAnalyticsContent,
    ),
    AppDefinition(
      id: 'shop',
      title: 'Shop',
      icon: Icons.shopping_cart_outlined,
      accentColor: Color(0xFFE91E63),
      contentBuilder: _buildShopContent,
    ),
    // Note: Chat and weather apps are handled specially - see openModal method
  ];

  // Open or restore a modal
  void openModal(String appId, {String? initialMessage}) {
    // Special handling for chat app with initial message
    if (appId == 'chat' && initialMessage != null && initialMessage.isNotEmpty) {
      // Check if this message was already added to avoid duplicates
      final messages = _chatManager.messages;
      final shouldAddMessage = messages.isEmpty ||
          messages.last.text != initialMessage ||
          !messages.last.isUser;

      if (shouldAddMessage) {
        _chatManager.addMessage(initialMessage, true);
      }
    }

    if (_minimizedModals.containsKey(appId)) {
      // Restore minimized modal
      final instance = _minimizedModals.remove(appId)!;
      instance.state = ModalState.normal;
      _openModals[appId] = instance;
      _invalidateCache();
      notifyListeners();
      return;
    }

    if (_openModals.containsKey(appId)) {
      // Modal already open and visible
      if (appId == 'chat' && initialMessage != null && initialMessage.isNotEmpty) {
        // If it's chat with a message, add the message but don't minimize
        final messages = _chatManager.messages;
        final shouldAddMessage = messages.isEmpty ||
            messages.last.text != initialMessage ||
            !messages.last.isUser;

        if (shouldAddMessage) {
          _chatManager.addMessage(initialMessage, true);
        }
      } else {
        // For other apps or chat without message, minimize the modal
        minimizeModal(appId);
      }
      return;
    }

    if (!canOpenMore) {
      if (!_showLimitNotification) {
        _showLimitNotification = true;
        notifyListeners();
        // Auto-hide notification after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_showLimitNotification) {
            _showLimitNotification = false;
            notifyListeners();
          }
        });
      }
      return;
    }

    // Special handling for chat and calendar apps
    Widget child;
    String title;
    IconData icon;
    double width;
    double height;

    if (appId == 'chat') {
      child = _buildChatContent();
      title = 'Chat';
      icon = Icons.chat_bubble_outline;
      width = 600;
      height = 500;
    } else if (appId == 'calendar') {
      child = _buildCalendarContent();
      title = 'Calendar';
      icon = Icons.calendar_today_outlined;
      width = 500;
      height = 420;
    } else if (appId == 'notes') {
      child = _buildNotesContent();
      title = 'Notes';
      icon = Icons.description_outlined;
      width = 550;
      height = 450;
    } else if (appId == 'weather') {
      child = _buildWeatherContent();
      title = 'Weather';
      icon = Icons.cloud_outlined;
      width = 480;
      height = 400;
    } else {
      final app = apps.firstWhere((a) => a.id == appId);
      child = app.contentBuilder();
      title = app.title;
      icon = app.icon;
      width = 450;
      height = 350;
    }

    // Create state notifier for this modal
    final stateNotifier = ValueNotifier<ModalState>(ModalState.normal);

    final modal = VosModal(
      appIcon: icon,
      title: title,
      initialWidth: width,
      initialHeight: height,
      initialPosition: _calculateModalPosition(),
      onClose: () => closeModal(appId),
      onMinimize: () => minimizeModal(appId),
      onFullscreen: () => fullscreenModal(appId),
      statusNotifier: appId == 'chat' ? _chatStatusNotifier : null,
      isActiveNotifier: appId == 'chat' ? _chatIsActiveNotifier : null,
      stateNotifier: stateNotifier,
      child: child,
    );

    _openModals[appId] = ModalInstance(
      appId: appId,
      modal: modal,
      stateNotifier: stateNotifier,
      openedAt: DateTime.now(),
    );

    _invalidateCache();
    notifyListeners();
  }

  void closeModal(String appId) {
    final hadOpen = _openModals.remove(appId) != null;
    final hadMinimized = _minimizedModals.remove(appId) != null;

    if (hadOpen || hadMinimized) {
      _invalidateCache();
      notifyListeners();
    }
  }

  void minimizeModal(String appId) {
    final instance = _openModals.remove(appId);
    if (instance != null) {
      instance.state = ModalState.minimized;
      _minimizedModals[appId] = instance;
      _invalidateCache();
      notifyListeners();
    }
  }

  void fullscreenModal(String appId) {
    // Check in open modals first
    var instance = _openModals[appId];

    // If not found, check minimized modals
    if (instance == null) {
      instance = _minimizedModals[appId];
    }

    if (instance != null) {
      // Toggle between fullscreen and normal
      if (instance.state == ModalState.fullscreen) {
        instance.state = ModalState.normal;
      } else {
        instance.state = ModalState.fullscreen;
      }

      // If it was minimized, move it back to open
      if (_minimizedModals.containsKey(appId)) {
        _minimizedModals.remove(appId);
        _openModals[appId] = instance;
      }

      _invalidateCache();
      notifyListeners();
    }
  }

  void dismissLimitNotification() {
    if (_showLimitNotification) {
      _showLimitNotification = false;
      notifyListeners();
    }
  }

  Offset _calculateModalPosition() {
    const baseX = 150.0;
    const baseY = 80.0;
    const offset = 30.0;

    final index = openModalCount;
    return Offset(
      baseX + (index * offset),
      baseY + (index * offset),
    );
  }

  bool isModalOpen(String appId) {
    return _openModals.containsKey(appId) || _minimizedModals.containsKey(appId);
  }

  bool isModalMinimized(String appId) {
    return _minimizedModals.containsKey(appId);
  }

  // Content builders for each app
  static Widget _buildPhoneContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_outlined, size: 64, color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text(
              'Phone App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Make and receive calls',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }


  static Widget _buildTasksContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF9C27B0)),
            SizedBox(height: 16),
            Text(
              'Tasks App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Track your to-dos',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }


  static Widget _buildBrowserContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language_outlined, size: 64, color: Color(0xFFFF5722)),
            SizedBox(height: 16),
            Text(
              'Browser App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Browse the web',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAnalyticsContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: Color(0xFF607D8B)),
            SizedBox(height: 16),
            Text(
              'Analytics App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'View your data insights',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildShopContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFE91E63)),
            SizedBox(height: 16),
            Text(
              'Shop App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Browse and buy products',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent() {
    return ChatApp(
      chatManager: _chatManager,
      chatService: _chatService,
      statusNotifier: _chatStatusNotifier,
      isActiveNotifier: _chatIsActiveNotifier,
    );
  }

  Widget _buildCalendarContent() {
    return const CalendarApp();
  }

  Widget _buildNotesContent() {
    return const NotesApp();
  }

  Widget _buildWeatherContent() {
    return WeatherApp(
      weatherService: _weatherService,
      chatService: _chatService,
    );
  }

}