import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/services/attachment_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/presentation/widgets/platform_image.dart';

/// Widget to display pending attachments before sending a message
class AttachmentPreview extends StatelessWidget {
  final VoidCallback? onClose;

  const AttachmentPreview({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final attachmentService = getIt<AttachmentService>();

    return ListenableBuilder(
      listenable: attachmentService,
      builder: (context, child) {
        final attachments = attachmentService.pendingAttachments;
        if (attachments.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AttachmentThumbnail(
                  attachment: attachment,
                  onRemove: () {
                    attachmentService.removePendingAttachment(attachment.localId);
                  },
                  onRetry: attachment.hasError
                      ? () => attachmentService.retryUpload(attachment.localId)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Individual attachment thumbnail with status indicator
class _AttachmentThumbnail extends StatelessWidget {
  final PendingAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image preview - uses bytes on web, file on mobile
                PlatformImage(
                  filePath: attachment.filePath,
                  bytes: attachment.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF424242),
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 32,
                      ),
                    );
                  },
                ),

                // Upload overlay
                if (attachment.isUploading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: attachment.uploadProgress,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ),

                // Error overlay
                if (attachment.hasError)
                  Container(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF5252),
                          size: 24,
                        ),
                        if (onRetry != null)
                          GestureDetector(
                            onTap: onRetry,
                            child: const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Success indicator
                if (attachment.isUploaded)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (attachment.hasError) return const Color(0xFFFF5252);
    if (attachment.isUploaded) return const Color(0xFF4CAF50);
    if (attachment.isUploading) return const Color(0xFF00BCD4);
    return Colors.white24;
  }
}

/// Compact attachment indicator for input bar
class AttachmentIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const AttachmentIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attachmentService = getIt<AttachmentService>();

    return ListenableBuilder(
      listenable: attachmentService,
      builder: (context, child) {
        final count = attachmentService.pendingCount;
        if (count == 0) return const SizedBox.shrink();

        final isUploading = attachmentService.isUploading;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUploading) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else
                  const Icon(
                    Icons.image,
                    size: 14,
                    color: Color(0xFF00BCD4),
                  ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
