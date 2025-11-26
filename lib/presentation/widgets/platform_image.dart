import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional imports for platform-specific file handling
import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_io.dart' as platform;

/// Platform-agnostic image widget that works on both web and mobile
/// Uses Image.memory on web (from bytes) and Image.file on mobile
class PlatformImage extends StatelessWidget {
  final String? filePath;
  final Uint8List? bytes;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const PlatformImage({
    super.key,
    this.filePath,
    this.bytes,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // On web or when we have bytes, use Image.memory
    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(
        bytes!,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    // On mobile with file path, use platform-specific file image
    if (!kIsWeb && filePath != null && filePath!.isNotEmpty && !filePath!.startsWith('memory://')) {
      return platform.buildFileImage(
        filePath: filePath!,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    // Fallback error widget
    return _buildErrorWidget(context);
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorBuilder != null) {
      return errorBuilder!(context, Exception('No image source'), null);
    }
    return Container(
      color: const Color(0xFF424242),
      child: const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 32,
      ),
    );
  }
}
