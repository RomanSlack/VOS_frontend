import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/services/attachment_service.dart';
import 'package:vos_app/core/di/injection.dart';

// Conditional import for File on non-web platforms
import 'image_viewer_stub.dart'
    if (dart.library.io) 'image_viewer_io.dart' as platform;

/// Full-screen image viewer with zoom and swipe support
class ImageViewer extends StatefulWidget {
  final List<ChatAttachment> attachments;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.attachments,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<String, String> _signedUrls = {};
  final FocusNode _focusNode = FocusNode();
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Initialize with pre-fetched URLs immediately
    for (final attachment in widget.attachments) {
      if (attachment.url != null && attachment.url!.isNotEmpty) {
        _signedUrls[attachment.attachmentId] = attachment.url!;
      }
    }

    // Load any missing URLs asynchronously
    _loadUrls();
  }

  Future<void> _loadUrls() async {
    final attachmentService = getIt<AttachmentService>();

    for (final attachment in widget.attachments) {
      if (attachment.localPath != null || attachment.hasLocalBytes) {
        continue;
      }

      if (_signedUrls.containsKey(attachment.attachmentId)) {
        continue;
      }

      final url = await attachmentService.getSignedUrl(attachment.attachmentId);
      if (url != null && mounted) {
        setState(() {
          _signedUrls[attachment.attachmentId] = url;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _downloadImage() async {
    final attachment = widget.attachments[_currentIndex];
    final url = attachment.url ?? _signedUrls[attachment.attachmentId];

    if (url != null && url.startsWith('http')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_currentIndex < widget.attachments.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close (Esc)',
          ),
          title: widget.attachments.length > 1
              ? Text(
                  '${_currentIndex + 1} / ${widget.attachments.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                )
              : null,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadImage,
              tooltip: 'Download',
            ),
          ],
        ),
        body: Column(
          children: [
            // Image viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.attachments.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final attachment = widget.attachments[index];
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildImage(attachment),
                    ),
                  );
                },
              ),
            ),

            // Page indicators for multiple images
            if (widget.attachments.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.attachments.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? const Color(0xFF00BCD4)
                            : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),

            // File name
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 16,
                right: 16,
              ),
              child: Text(
                widget.attachments[_currentIndex].fileName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ChatAttachment attachment) {
    // Use bytes if available (web - newly uploaded)
    if (attachment.hasLocalBytes) {
      return Image.memory(
        attachment.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // Use local file path if available (mobile)
    if (attachment.localPath != null && !kIsWeb) {
      return platform.buildFileImage(
        attachment.localPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // Use signed URL with plain Image.network (no CachedNetworkImage)
    final signedUrl = _signedUrls[attachment.attachmentId];
    if (signedUrl != null) {
      return Image.network(
        signedUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00BCD4)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // Loading state
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load image',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
