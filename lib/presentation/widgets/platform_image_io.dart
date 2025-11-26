import 'dart:io';
import 'package:flutter/material.dart';

/// IO implementation for mobile - uses dart:io File
Widget buildFileImage({
  required String filePath,
  required BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.file(
    File(filePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
