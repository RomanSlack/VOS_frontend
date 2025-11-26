import 'dart:io';
import 'package:flutter/material.dart';

/// IO implementation for mobile - uses dart:io File
ImageProvider createFileImageProvider(String filePath) {
  return FileImage(File(filePath));
}

/// Build an Image widget from a file path (mobile only)
Widget buildFileImage(
  String filePath, {
  BoxFit? fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.file(
    File(filePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
