import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vos_app/core/chat_manager.dart';
import 'package:vos_app/core/services/chat_service.dart';
import 'package:vos_app/core/models/chat_models.dart';

class BrowserApp extends StatefulWidget {
  final ChatManager? chatManager;
  final ChatService? chatService;

  const BrowserApp({
    super.key,
    this.chatManager,
    this.chatService,
  });

  @override
  State<BrowserApp> createState() => _BrowserAppState();
}

class _BrowserAppState extends State<BrowserApp> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  String? _currentUrl;
  String? _currentTitle;
  Uint8List? _screenshotBytes;
  bool _isLoading = false;
  String? _errorMessage;

  // History
  final List<String> _history = [];
  int _historyIndex = -1;
  
  // Screenshot stream subscription
  StreamSubscription<BrowserScreenshotPayload>? _screenshotSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for browser notifications from chat manager
    widget.chatManager?.addListener(_onChatUpdate);
    
    // Subscribe to browser screenshot stream
    _screenshotSubscription = widget.chatService?.browserScreenshotStream.listen(_onScreenshotReceived);
  }

  @override
  void dispose() {
    widget.chatManager?.removeListener(_onChatUpdate);
    _screenshotSubscription?.cancel();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }
  
  void _onScreenshotReceived(BrowserScreenshotPayload payload) {
    debugPrint('BrowserApp received screenshot for ${payload.currentUrl}');
    if (payload.currentUrl != null) {
      setState(() {
        _currentUrl = payload.currentUrl;
        _urlController.text = payload.currentUrl!;
      });
    }
    _displayScreenshot(payload.screenshotBase64);
  }

  void _onChatUpdate() {
    // Listen for browser agent responses in chat messages
    final messages = widget.chatManager?.messages ?? [];
    if (messages.isEmpty) return;

    // Look for recent AI messages that might contain screenshot info
    for (var i = messages.length - 1; i >= 0 && i >= messages.length - 5; i--) {
      final message = messages[i];
      if (message.isUser) continue;

      // Check if this is a browser-related response
      final text = message.text.toLowerCase();
      if (text.contains('screenshot') ||
          text.contains('navigat') ||
          text.contains('browser')) {

        // For now, just stop loading when we get a response
        if (_isLoading) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
        break;
      }
    }
  }

  void _displayScreenshot(String base64Screenshot) {
    try {
      final bytes = base64Decode(base64Screenshot);
      setState(() {
        _screenshotBytes = bytes;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to decode screenshot';
        _isLoading = false;
      });
    }
  }
  void _navigateToUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Ensure URL has protocol
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentUrl = fullUrl;
      _currentTitle = fullUrl;
    });

    // Add to history
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(fullUrl);
    _historyIndex = _history.length - 1;

    // Simulate loading complete after brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _goBack() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _currentUrl = _history[_historyIndex];
        _urlController.text = _currentUrl ?? '';
      });
      _navigateToUrl();
    }
  }

  void _goForward() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _currentUrl = _history[_historyIndex];
        _urlController.text = _currentUrl ?? '';
      });
      _navigateToUrl();
    }
  }

  void _refresh() {
    if (_currentUrl != null) {
      _navigateToUrl();
    }
  }

  void _goHome() {
    setState(() {
      _urlController.text = 'google.com';
    });
    _navigateToUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          _buildToolbar(),
          _buildAddressBar(),
          Expanded(
            child: _buildContent(),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onPressed: _historyIndex > 0 ? _goBack : null,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.arrow_forward,
            tooltip: 'Forward',
            onPressed: _historyIndex < _history.length - 1 ? _goForward : null,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: _currentUrl != null ? _refresh : null,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.home_outlined,
            tooltip: 'Home',
            onPressed: _goHome,
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? const Color(0xFFEDEDED)
                : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _currentUrl != null && _currentUrl!.startsWith('https://')
                ? Icons.lock_outline
                : Icons.public,
            size: 16,
            color: const Color(0xFF757575),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter URL or search...',
                hintStyle: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF00BCD4),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: const Color(0xFF212121),
              ),
              onSubmitted: (_) => _navigateToUrl(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToUrl,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // If we have a screenshot from the browser agent, display it
    if (_screenshotBytes != null) {
      return InteractiveViewer(
        child: Center(
          child: Image.memory(
            _screenshotBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // If we have a URL but no screenshot yet, show loading/waiting message
    if (_currentUrl != null && _currentUrl!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              )
            else
              const Icon(
                Icons.photo_camera_outlined,
                size: 64,
                color: Color(0xFF757575),
              ),
            const SizedBox(height: 16),
            Text(
              _isLoading ? 'Waiting for browser agent...' : 'No screenshot yet',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUrl!,
              style: const TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ask the AI to browse this URL to see it here',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Welcome screen
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.language_outlined,
            size: 96,
            color: Color(0xFF00BCD4),
          ),
          const SizedBox(height: 24),
          const Text(
            'VOS Browser',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Browse the web directly in VOS',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF303030),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Color(0xFF00BCD4)),
                    SizedBox(width: 8),
                    Text(
                      'Quick Start:',
                      style: TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickStartItem(
                  '1. Ask the AI to browse a website',
                ),
                const SizedBox(height: 8),
                _buildQuickStartItem(
                  '2. The browser agent will navigate and capture',
                ),
                const SizedBox(height: 8),
                _buildQuickStartItem(
                  '3. Screenshots appear here automatically!',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFF00BCD4)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI-Powered Browsing',
                              style: TextStyle(
                                color: Color(0xFF00BCD4),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Example commands:',
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• "Go to google.com"\n• "Search for weather in NYC"\n• "Navigate to wikipedia.org"',
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          size: 16,
          color: Color(0xFF00BCD4),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentUrl != null) ...[
            Icon(
              Icons.check_circle,
              size: 12,
              color: _screenshotBytes != null
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF757575),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _currentTitle ?? _currentUrl!,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Ready',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 11,
                ),
              ),
            ),
          if (_isLoading)
            const Text(
              'Loading...',
              style: TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
