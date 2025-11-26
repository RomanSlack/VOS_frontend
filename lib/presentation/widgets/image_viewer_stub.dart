import 'package:flutter/material.dart';

/// Stub implementation for web - returns a placeholder ImageProvider
ImageProvider createFileImageProvider(String filePath) {
  // On web, we should never reach here as we use bytes
  // Return a transparent placeholder
  return const AssetImage('assets/images/placeholder.png');
}

/// Stub for web - should never be called (we use bytes on web)
Widget buildFileImage(
  String filePath, {
  BoxFit? fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // On web, this should never be called
  return const Center(
    child: Icon(Icons.image_not_supported, color: Colors.white54),
  );
}
