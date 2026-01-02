import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vos_app/core/api/attachment_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/core/di/injection.dart';

/// Service for managing image attachments
class AttachmentService extends ChangeNotifier {
  late final Dio _dio;
  late final AttachmentApi _api;
  final ImagePicker _imagePicker = ImagePicker();
  final SessionService _sessionService = SessionService();

  // Pending attachments waiting to be sent with a message
  final List<PendingAttachment> _pendingAttachments = [];

  // Cache for signed URLs (attachment_id -> url info)
  final Map<String, _CachedUrl> _urlCache = {};

  // Allowed image types
  static const List<String> allowedMimeTypes = [
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  ];

  // Max file size (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  AttachmentService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
    ));

    // JWT authentication only (no API key - security fix)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }

          // Add JWT token for authentication
          final authService = getIt<AuthService>();
          final token = await authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add session ID
          final sessionId = await _sessionService.getSessionId();
          options.headers['X-Session-ID'] = sessionId;

          return handler.next(options);
        },
      ),
    );

    _api = AttachmentApi(_dio);
  }

  // Getters
  List<PendingAttachment> get pendingAttachments =>
      List.unmodifiable(_pendingAttachments);

  bool get hasPendingAttachments => _pendingAttachments.isNotEmpty;

  int get pendingCount => _pendingAttachments.length;

  bool get isUploading =>
      _pendingAttachments.any((a) => a.status == AttachmentUploadStatus.uploading);

  /// Pick images from gallery
  Future<List<PendingAttachment>> pickImages({int maxImages = 5}) async {
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (files.isEmpty) return [];

      // Limit number of images
      final limitedFiles = files.take(maxImages).toList();

      final List<PendingAttachment> newAttachments = [];

      for (final file in limitedFiles) {
        final attachment = await _createPendingAttachment(file);
        if (attachment != null) {
          newAttachments.add(attachment);
        }
      }

      _pendingAttachments.addAll(newAttachments);
      notifyListeners();

      // Start uploading
      for (final attachment in newAttachments) {
        _uploadAttachment(attachment);
      }

      return newAttachments;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Pick image from camera
  Future<PendingAttachment?> pickFromCamera() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (file == null) return null;

      final attachment = await _createPendingAttachment(file);
      if (attachment == null) return null;

      _pendingAttachments.add(attachment);
      notifyListeners();

      // Start uploading
      _uploadAttachment(attachment);

      return attachment;
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Add attachment from file path (for drag-and-drop or paste)
  Future<PendingAttachment?> addFromPath(String filePath) async {
    try {
      final file = XFile(filePath);
      final attachment = await _createPendingAttachment(file);
      if (attachment == null) return null;

      _pendingAttachments.add(attachment);
      notifyListeners();

      // Start uploading
      _uploadAttachment(attachment);

      return attachment;
    } catch (e) {
      debugPrint('Error adding attachment from path: $e');
      return null;
    }
  }

  /// Add attachment from bytes (for clipboard paste)
  Future<PendingAttachment?> addFromBytes(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      // Validate mime type
      if (!allowedMimeTypes.contains(mimeType)) {
        debugPrint('Invalid mime type: $mimeType');
        return null;
      }

      // Validate file size
      if (bytes.length > maxFileSizeBytes) {
        debugPrint('File too large: ${bytes.length} bytes');
        return null;
      }

      // Store bytes directly - works on both web and mobile
      final attachment = PendingAttachment(
        localId: const Uuid().v4(),
        filePath: 'memory://$fileName', // Virtual path for bytes-based attachment
        fileName: fileName,
        mimeType: mimeType,
        fileSize: bytes.length,
        status: AttachmentUploadStatus.pending,
        bytes: bytes, // Store bytes directly
      );

      _pendingAttachments.add(attachment);
      notifyListeners();

      // Start uploading
      _uploadAttachment(attachment);

      return attachment;
    } catch (e) {
      debugPrint('Error adding attachment from bytes: $e');
      return null;
    }
  }

  /// Create a PendingAttachment from an XFile
  Future<PendingAttachment?> _createPendingAttachment(XFile file) async {
    final mimeType = _getMimeType(file.name) ?? file.mimeType ?? 'image/jpeg';

    // Validate mime type
    if (!allowedMimeTypes.contains(mimeType)) {
      debugPrint('Invalid file type: $mimeType');
      return null;
    }

    // Get file size
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      debugPrint('File too large: $fileSize bytes (max: $maxFileSizeBytes)');
      return null;
    }

    // For web, read bytes immediately for preview and upload
    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await file.readAsBytes();
    }

    return PendingAttachment(
      localId: const Uuid().v4(),
      filePath: file.path,
      fileName: file.name,
      mimeType: mimeType,
      fileSize: fileSize,
      status: AttachmentUploadStatus.pending,
      xFile: file, // Store XFile reference for later upload
      bytes: bytes, // Store bytes for web
    );
  }

  /// Upload a pending attachment
  Future<void> _uploadAttachment(PendingAttachment attachment) async {
    final index = _pendingAttachments.indexWhere(
      (a) => a.localId == attachment.localId,
    );
    if (index == -1) return;

    // Update status to uploading
    _pendingAttachments[index] = attachment.copyWith(
      status: AttachmentUploadStatus.uploading,
      uploadProgress: 0.0,
    );
    notifyListeners();

    try {
      final sessionId = await _sessionService.getSessionId();

      // Get file data - use bytes for web, file path for mobile
      dynamic fileData;
      if (kIsWeb) {
        // For web, use stored bytes or read from XFile
        fileData = attachment.bytes ?? await attachment.xFile?.readAsBytes();
        if (fileData == null) {
          throw Exception('No file data available for upload');
        }
      } else {
        // For mobile, use file path
        fileData = attachment.filePath;
      }

      final response = await _dio.uploadAttachmentWithProgress(
        fileData,
        sessionId,
        attachment.fileName,
        attachment.mimeType,
        onProgress: (sent, total) {
          final progress = sent / total;
          final currentIndex = _pendingAttachments.indexWhere(
            (a) => a.localId == attachment.localId,
          );
          if (currentIndex != -1) {
            _pendingAttachments[currentIndex] = _pendingAttachments[currentIndex].copyWith(
              uploadProgress: progress,
            );
            notifyListeners();
          }
        },
      );

      // Update with successful upload
      final finalIndex = _pendingAttachments.indexWhere(
        (a) => a.localId == attachment.localId,
      );
      if (finalIndex != -1) {
        _pendingAttachments[finalIndex] = _pendingAttachments[finalIndex].copyWith(
          status: AttachmentUploadStatus.uploaded,
          attachmentId: response.attachmentId,
          uploadProgress: 1.0,
          width: response.width,
          height: response.height,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error uploading attachment: $e');

      // Update with error
      final errorIndex = _pendingAttachments.indexWhere(
        (a) => a.localId == attachment.localId,
      );
      if (errorIndex != -1) {
        _pendingAttachments[errorIndex] = _pendingAttachments[errorIndex].copyWith(
          status: AttachmentUploadStatus.error,
          errorMessage: e.toString(),
        );
        notifyListeners();
      }
    }
  }

  /// Retry a failed upload
  Future<void> retryUpload(String localId) async {
    final index = _pendingAttachments.indexWhere((a) => a.localId == localId);
    if (index == -1) return;

    final attachment = _pendingAttachments[index];
    if (attachment.status != AttachmentUploadStatus.error) return;

    _pendingAttachments[index] = attachment.copyWith(
      status: AttachmentUploadStatus.pending,
      errorMessage: null,
    );
    notifyListeners();

    _uploadAttachment(_pendingAttachments[index]);
  }

  /// Remove a pending attachment
  void removePendingAttachment(String localId) {
    _pendingAttachments.removeWhere((a) => a.localId == localId);
    notifyListeners();
  }

  /// Clear all pending attachments
  void clearPendingAttachments() {
    _pendingAttachments.clear();
    notifyListeners();
  }

  /// Get attachment IDs for uploaded attachments
  List<String> getUploadedAttachmentIds() {
    return _pendingAttachments
        .where((a) => a.status == AttachmentUploadStatus.uploaded && a.attachmentId != null)
        .map((a) => a.attachmentId!)
        .toList();
  }

  /// Check if all attachments are uploaded
  bool get allUploaded {
    if (_pendingAttachments.isEmpty) return true;
    return _pendingAttachments.every(
      (a) => a.status == AttachmentUploadStatus.uploaded,
    );
  }

  /// Get a signed URL for an attachment (with caching)
  Future<String?> getSignedUrl(String attachmentId) async {
    // Check cache first
    final cached = _urlCache[attachmentId];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    try {
      final response = await _api.getAttachmentUrl(attachmentId);

      // Handle relative URLs - prepend API base URL if needed
      String fullUrl = response.url;
      if (!fullUrl.startsWith('http')) {
        fullUrl = '${AppConfig.apiBaseUrl}${fullUrl.startsWith('/') ? '' : '/'}$fullUrl';
      }

      // Cache the URL with expiration buffer
      final expiresInSeconds = response.expiresIn;
      _urlCache[attachmentId] = _CachedUrl(
        url: fullUrl,
        expiresAt: DateTime.now().add(
          Duration(seconds: expiresInSeconds > 60 ? expiresInSeconds - 60 : expiresInSeconds),
        ),
      );

      return fullUrl;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }

  /// Get attachment metadata
  Future<AttachmentMetadata?> getAttachmentMetadata(String attachmentId) async {
    try {
      return await _api.getAttachment(attachmentId);
    } catch (e) {
      debugPrint('Error getting attachment metadata: $e');
      return null;
    }
  }

  /// Convert pending attachments to ChatAttachments
  Future<List<ChatAttachment>> convertToChatAttachments() async {
    final attachments = <ChatAttachment>[];

    for (final pending in _pendingAttachments) {
      if (pending.attachmentId != null) {
        attachments.add(ChatAttachment(
          attachmentId: pending.attachmentId!,
          localPath: kIsWeb ? null : pending.filePath, // Only use path on mobile
          fileName: pending.fileName,
          contentType: pending.mimeType,
          width: pending.width,
          height: pending.height,
          bytes: pending.bytes, // Pass bytes for web preview
        ));
      }
    }

    return attachments;
  }

  /// Get MIME type from file name
  String? _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}

/// Cached URL with expiration
class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl({required this.url, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
