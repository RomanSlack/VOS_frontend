import 'package:flutter/material.dart';

/// Stub implementation for web - returns empty widget since we use bytes
Widget buildFileImage({
  required String filePath,
  required BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // On web, we should never reach here as we use bytes
  // Return error widget as fallback
  return Container(
    color: const Color(0xFF424242),
    child: const Icon(
      Icons.broken_image,
      color: Colors.white54,
      size: 32,
    ),
  );
}
