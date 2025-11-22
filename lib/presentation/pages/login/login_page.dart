import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/router/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sessionController = TextEditingController();
  final _authService = AuthService();
  final _sessionService = SessionService();

  bool _isLoading = false;
  bool _isLoadingSessions = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  List<SessionInfoDto> _existingSessions = [];
  String? _selectedExistingSession;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // Generate a default session name
    final defaultName = _sessionService.generateSessionName();
    _sessionController.text = defaultName;

    // Load existing sessions
    await _loadExistingSessions();
  }

  Future<void> _loadExistingSessions() async {
    setState(() {
      _isLoadingSessions = true;
    });

    try {
      final sessions = await _sessionService.listSessions();
      if (mounted) {
        setState(() {
          _existingSessions = sessions;
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sessions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      // Save the selected session
      final sessionId = _selectedExistingSession ?? _sessionController.text.trim();
      await _sessionService.setSessionId(sessionId);

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BCD4).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'VOS Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF5252).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFFF5252),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFF303030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00BCD4),
                          width: 2,
                        ),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF757575)),
                      prefixIconColor: const Color(0xFF757575),
                    ),
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF303030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00BCD4),
                          width: 2,
                        ),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF757575)),
                      prefixIconColor: const Color(0xFF757575),
                      suffixIconColor: const Color(0xFF757575),
                    ),
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 16),

                  // Session name field
                  TextFormField(
                    controller: _sessionController,
                    enabled: !_isLoading && _selectedExistingSession == null,
                    decoration: InputDecoration(
                      labelText: 'Session Name',
                      hintText: 'Enter a name for this session',
                      prefixIcon: const Icon(Icons.devices_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _sessionController.text =
                                      _sessionService.generateSessionName();
                                  _selectedExistingSession = null;
                                });
                              },
                        tooltip: 'Generate new name',
                      ),
                      filled: true,
                      fillColor: const Color(0xFF303030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00BCD4),
                          width: 2,
                        ),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF757575)),
                      hintStyle: const TextStyle(color: Color(0xFF616161)),
                      prefixIconColor: const Color(0xFF757575),
                      suffixIconColor: const Color(0xFF757575),
                    ),
                    style: const TextStyle(color: Color(0xFFEDEDED)),
                    validator: (value) {
                      if (_selectedExistingSession == null &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter a session name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Existing sessions dropdown
                  if (_existingSessions.isNotEmpty || _isLoadingSessions)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF303030),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: _isLoadingSessions
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedExistingSession,
                              decoration: const InputDecoration(
                                labelText: 'Or select existing session',
                                prefixIcon: Icon(Icons.history),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                labelStyle: TextStyle(color: Color(0xFF757575)),
                                prefixIconColor: Color(0xFF757575),
                              ),
                              dropdownColor: const Color(0xFF424242),
                              style: const TextStyle(color: Color(0xFFEDEDED)),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF757575),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'Create new session',
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                ..._existingSessions.map((session) {
                                  return DropdownMenuItem<String>(
                                    value: session.sessionId,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          session.sessionId,
                                          style: const TextStyle(
                                            color: Color(0xFFEDEDED),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${session.messageCount} messages',
                                          style: const TextStyle(
                                            color: Color(0xFF757575),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedExistingSession = value;
                                      });
                                    },
                            ),
                    ),
                  const SizedBox(height: 16),

                  // Remember Me checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? true;
                                });
                              },
                        activeColor: const Color(0xFF00BCD4),
                        checkColor: Colors.white,
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Login button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF424242),
                        disabledForegroundColor: const Color(0xFF757575),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
