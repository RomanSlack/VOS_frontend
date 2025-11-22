import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/router/app_routes.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  String? _username;
  final String _sessionId = 'user_session_default'; // Default session ID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authService = AuthService();
    final username = await authService.getUsername();

    if (mounted) {
      setState(() {
        _username = username ?? 'Guest';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (context.mounted) {
      Navigator.of(context).pop(); // Close dialog
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF303030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00BCD4),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with profile icon
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00BCD4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF00BCD4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                color: Color(0xFFEDEDED),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _username ?? 'Guest',
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 20),

                  // Session info
                  _buildInfoRow(
                    Icons.badge_outlined,
                    'Username',
                    _username ?? 'Guest',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.fingerprint,
                    'Session ID',
                    _sessionId,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 20),

                  // Settings button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        context.push(AppRoutes.settings);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00BCD4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF00BCD4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF00BCD4),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
