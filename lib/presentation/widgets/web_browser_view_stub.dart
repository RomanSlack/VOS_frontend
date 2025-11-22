import 'package:flutter/material.dart';

/// Stub for web browser view on non-web platforms
class WebBrowserView extends StatefulWidget {
  final String? initialUrl;
  final Function(String)? onUrlChanged;

  const WebBrowserView({
    super.key,
    this.initialUrl,
    this.onUrlChanged,
  });

  @override
  State<WebBrowserView> createState() => _WebBrowserViewState();
}

class _WebBrowserViewState extends State<WebBrowserView> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Web browser is only available on web platform',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  void loadUrl(String url) {
    // Stub - does nothing on non-web platforms
  }
}
