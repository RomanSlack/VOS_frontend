import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/services/attachment_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/presentation/widgets/image_viewer.dart';
import 'package:vos_app/presentation/widgets/platform_image.dart';

/// Widget to display attachments in a chat message
class MessageAttachments extends StatelessWidget {
  final List<ChatAttachment> attachments;
  final bool isUserMessage;

  const MessageAttachments({
    super.key,
    required this.attachments,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // Filter to only images for now
    final images = attachments.where((a) => a.isImage).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    // Single image
    if (images.length == 1) {
      return _SingleImageAttachment(
        attachment: images.first,
        isUserMessage: isUserMessage,
      );
    }

    // Multiple images - grid layout
    return _ImageGrid(
      attachments: images,
      isUserMessage: isUserMessage,
    );
  }
}

/// Single image attachment display
class _SingleImageAttachment extends StatefulWidget {
  final ChatAttachment attachment;
  final bool isUserMessage;

  const _SingleImageAttachment({
    required this.attachment,
    required this.isUserMessage,
  });

  @override
  State<_SingleImageAttachment> createState() => _SingleImageAttachmentState();
}

class _SingleImageAttachmentState extends State<_SingleImageAttachment> {
  String? _signedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    // Use local path or bytes first (for newly uploaded images)
    if (widget.attachment.localPath != null || widget.attachment.hasLocalBytes) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Use pre-fetched URL if available (from ChatService._fetchAttachmentsMetadata)
    if (widget.attachment.url != null && widget.attachment.url!.isNotEmpty) {
      setState(() {
        _signedUrl = widget.attachment.url;
        _isLoading = false;
      });
      return;
    }

    // Fallback: fetch signed URL if not pre-fetched
    final attachmentService = getIt<AttachmentService>();
    final url = await attachmentService.getSignedUrl(widget.attachment.attachmentId);

    if (mounted) {
      setState(() {
        _signedUrl = url;
        _isLoading = false;
        _hasError = url == null;
      });
    }
  }

  void _openViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          attachments: [widget.attachment],
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openViewer,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
          maxHeight: 200,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF424242),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
          ),
        ),
      );
    }

    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF424242),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 32),
              SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Use local path or bytes if available
    if (widget.attachment.localPath != null || widget.attachment.hasLocalBytes) {
      return PlatformImage(
        filePath: widget.attachment.localPath,
        bytes: widget.attachment.bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    // Use signed URL
    if (_signedUrl != null) {
      return CachedNetworkImage(
        imageUrl: _signedUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF424242),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 32),
          SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Grid layout for multiple images
class _ImageGrid extends StatelessWidget {
  final List<ChatAttachment> attachments;
  final bool isUserMessage;

  const _ImageGrid({
    required this.attachments,
    required this.isUserMessage,
  });

  @override
  Widget build(BuildContext context) {
    final count = attachments.length;

    // 2 images: side by side
    if (count == 2) {
      return _buildTwoImages(context);
    }

    // 3 images: 2 on top, 1 on bottom
    if (count == 3) {
      return _buildThreeImages(context);
    }

    // 4+ images: 2x2 grid with overflow indicator
    return _buildFourPlusImages(context);
  }

  Widget _buildTwoImages(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _GridImageTile(
              attachment: attachments[0],
              allAttachments: attachments,
              index: 0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _GridImageTile(
              attachment: attachments[1],
              allAttachments: attachments,
              index: 1,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GridImageTile(
                  attachment: attachments[0],
                  allAttachments: attachments,
                  index: 0,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _GridImageTile(
                  attachment: attachments[1],
                  allAttachments: attachments,
                  index: 1,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _GridImageTile(
            attachment: attachments[2],
            allAttachments: attachments,
            index: 2,
            height: 80,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourPlusImages(BuildContext context) {
    final extraCount = attachments.length - 4;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GridImageTile(
                  attachment: attachments[0],
                  allAttachments: attachments,
                  index: 0,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _GridImageTile(
                  attachment: attachments[1],
                  allAttachments: attachments,
                  index: 1,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: _GridImageTile(
                  attachment: attachments[2],
                  allAttachments: attachments,
                  index: 2,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  children: [
                    _GridImageTile(
                      attachment: attachments[3],
                      allAttachments: attachments,
                      index: 3,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    if (extraCount > 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$extraCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual tile in the image grid
class _GridImageTile extends StatefulWidget {
  final ChatAttachment attachment;
  final List<ChatAttachment> allAttachments;
  final int index;
  final BorderRadius borderRadius;
  final double? height;

  const _GridImageTile({
    required this.attachment,
    required this.allAttachments,
    required this.index,
    required this.borderRadius,
    this.height,
  });

  @override
  State<_GridImageTile> createState() => _GridImageTileState();
}

class _GridImageTileState extends State<_GridImageTile> {
  String? _signedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    // Use local path or bytes first (for newly uploaded images)
    if (widget.attachment.localPath != null || widget.attachment.hasLocalBytes) {
      setState(() => _isLoading = false);
      return;
    }

    // Use pre-fetched URL if available (from ChatService._fetchAttachmentsMetadata)
    if (widget.attachment.url != null && widget.attachment.url!.isNotEmpty) {
      setState(() {
        _signedUrl = widget.attachment.url;
        _isLoading = false;
      });
      return;
    }

    // Fallback: fetch signed URL if not pre-fetched
    final attachmentService = getIt<AttachmentService>();
    final url = await attachmentService.getSignedUrl(widget.attachment.attachmentId);

    if (mounted) {
      setState(() {
        _signedUrl = url;
        _isLoading = false;
      });
    }
  }

  void _openViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          attachments: widget.allAttachments,
          initialIndex: widget.index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openViewer,
      child: Container(
        height: widget.height ?? 100,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: const Color(0xFF424242),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
          ),
        ),
      );
    }

    if (widget.attachment.localPath != null || widget.attachment.hasLocalBytes) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: PlatformImage(
          filePath: widget.attachment.localPath,
          bytes: widget.attachment.bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      );
    }

    if (_signedUrl != null) {
      return CachedNetworkImage(
        imageUrl: _signedUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white38, size: 24),
    );
  }
}
