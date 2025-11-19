// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Real web browser view using iframe (Flutter web only)
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
  late html.IFrameElement _iframeElement;
  final String _viewType = 'vos-browser-iframe-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _createIframeElement();
  }

  void _createIframeElement() {
    _iframeElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Set sandbox attribute using setAttribute
    _iframeElement.setAttribute('sandbox', 'allow-same-origin allow-scripts allow-popups allow-forms allow-modals');
    _iframeElement.setAttribute('allow', 'fullscreen');

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _iframeElement.src = widget.initialUrl;
    }

    // Listen for load errors (CORS/X-Frame-Options violations)
    _iframeElement.onError.listen((event) {
      widget.onUrlChanged?.call('error');
    });

    // Register the iframe element as a platform view
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement,
    );
  }

  void loadUrl(String url) {
    _iframeElement.src = url;
    widget.onUrlChanged?.call(url);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
    );
  }
}
