import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/vos_modal.dart';

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
  ModalState state;
  final DateTime openedAt;

  ModalInstance({
    required this.appId,
    required this.modal,
    this.state = ModalState.normal,
    required this.openedAt,
  });
}

class VosModalManager extends ChangeNotifier {
  static const int maxModals = 4;

  final Map<String, ModalInstance> _openModals = {};
  final Map<String, ModalInstance> _minimizedModals = {};
  bool _showLimitNotification = false;

  // Getters
  List<ModalInstance> get openModals => _openModals.values.toList();
  List<ModalInstance> get minimizedModals => _minimizedModals.values.toList();
  bool get showLimitNotification => _showLimitNotification;
  int get openModalCount => _openModals.length + _minimizedModals.length;
  bool get canOpenMore => openModalCount < maxModals;

  // App definitions
  static const List<AppDefinition> apps = [
    AppDefinition(
      id: 'phone',
      title: 'Phone',
      icon: Icons.phone_outlined,
      accentColor: Color(0xFF4CAF50),
      contentBuilder: _buildPhoneContent,
    ),
    AppDefinition(
      id: 'calendar',
      title: 'Calendar',
      icon: Icons.calendar_today_outlined,
      accentColor: Color(0xFF2196F3),
      contentBuilder: _buildCalendarContent,
    ),
    AppDefinition(
      id: 'tasks',
      title: 'Tasks',
      icon: Icons.check_circle_outline,
      accentColor: Color(0xFF9C27B0),
      contentBuilder: _buildTasksContent,
    ),
    AppDefinition(
      id: 'notes',
      title: 'Notes',
      icon: Icons.description_outlined,
      accentColor: Color(0xFFFF9800),
      contentBuilder: _buildNotesContent,
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
    AppDefinition(
      id: 'chat',
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      accentColor: Color(0xFF00BCD4),
      contentBuilder: _buildChatContent,
    ),
    AppDefinition(
      id: 'notifications',
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      accentColor: Color(0xFFFFEB3B),
      contentBuilder: _buildNotificationsContent,
    ),
  ];

  // Open or restore a modal
  void openModal(String appId) {
    if (_minimizedModals.containsKey(appId)) {
      // Restore minimized modal
      final instance = _minimizedModals.remove(appId)!;
      instance.state = ModalState.normal;
      _openModals[appId] = instance;
      notifyListeners();
      return;
    }

    if (_openModals.containsKey(appId)) {
      // Modal already open, just notify to bring to front
      notifyListeners();
      return;
    }

    if (!canOpenMore) {
      _showLimitNotification = true;
      notifyListeners();
      // Auto-hide notification after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _showLimitNotification = false;
        notifyListeners();
      });
      return;
    }

    final app = apps.firstWhere((a) => a.id == appId);
    final modal = VosModal(
      appIcon: app.icon,
      title: app.title,
      initialWidth: 450,
      initialHeight: 350,
      initialPosition: _calculateModalPosition(),
      onClose: () => closeModal(appId),
      onMinimize: () => minimizeModal(appId),
      child: app.contentBuilder(),
    );

    _openModals[appId] = ModalInstance(
      appId: appId,
      modal: modal,
      openedAt: DateTime.now(),
    );

    notifyListeners();
  }

  void closeModal(String appId) {
    _openModals.remove(appId);
    _minimizedModals.remove(appId);
    notifyListeners();
  }

  void minimizeModal(String appId) {
    final instance = _openModals.remove(appId);
    if (instance != null) {
      instance.state = ModalState.minimized;
      _minimizedModals[appId] = instance;
      notifyListeners();
    }
  }

  void dismissLimitNotification() {
    _showLimitNotification = false;
    notifyListeners();
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

  static Widget _buildCalendarContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text(
              'Calendar App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your schedule',
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

  static Widget _buildNotesContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Color(0xFFFF9800)),
            SizedBox(height: 16),
            Text(
              'Notes App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Write and organize notes',
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

  static Widget _buildChatContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF00BCD4)),
            SizedBox(height: 16),
            Text(
              'Chat App',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Message with friends',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNotificationsContent() {
    return Container(
      color: const Color(0xFF212121),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined, size: 64, color: Color(0xFFFFEB3B)),
            SizedBox(height: 16),
            Text(
              'Notifications',
              style: TextStyle(color: Color(0xFFEDEDED), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'View all notifications',
              style: TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}