import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attachment_models.g.dart';

/// Response from uploading an attachment
@JsonSerializable()
class AttachmentUploadResponse {
  @JsonKey(name: 'attachment_id')
  final String attachmentId;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'file_size_bytes')
  final int fileSizeBytes;
  final int? width;
  final int? height;

  const AttachmentUploadResponse({
    required this.attachmentId,
    required this.contentType,
    required this.fileSizeBytes,
    this.width,
    this.height,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentUploadResponseToJson(this);
}

/// Full attachment metadata
@JsonSerializable()
class AttachmentMetadata {
  @JsonKey(name: 'attachment_id')
  final String attachmentId;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'attachment_type')
  final String attachmentType;
  @JsonKey(name: 'original_filename')
  final String originalFilename;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'file_size_bytes')
  final int fileSizeBytes;
  @JsonKey(name: 'storage_path')
  final String? storagePath;
  final int? width;
  final int? height;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const AttachmentMetadata({
    required this.attachmentId,
    required this.sessionId,
    required this.attachmentType,
    required this.originalFilename,
    required this.contentType,
    required this.fileSizeBytes,
    this.storagePath,
    this.width,
    this.height,
    required this.createdAt,
  });

  factory AttachmentMetadata.fromJson(Map<String, dynamic> json) =>
      _$AttachmentMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentMetadataToJson(this);

  bool get isImage => contentType.startsWith('image/');
}

/// Signed URL response for viewing/downloading attachments
@JsonSerializable()
class AttachmentUrlResponse {
  final String url;

  /// Expires in seconds (optional - backend may send expires_at instead)
  @JsonKey(name: 'expires_in')
  final int? expiresInSeconds;

  /// Expires at ISO timestamp (optional - backend may send expires_in instead)
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  const AttachmentUrlResponse({
    required this.url,
    this.expiresInSeconds,
    this.expiresAt,
  });

  factory AttachmentUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentUrlResponseToJson(this);

  /// Get expiration duration in seconds, handling both expires_in and expires_at
  int get expiresIn {
    if (expiresInSeconds != null) {
      return expiresInSeconds!;
    }
    if (expiresAt != null) {
      try {
        final expiresAtTime = DateTime.parse(expiresAt!);
        final now = DateTime.now();
        final difference = expiresAtTime.difference(now).inSeconds;
        return difference > 0 ? difference : 0;
      } catch (_) {
        return 3600; // Default 1 hour
      }
    }
    return 3600; // Default 1 hour
  }
}

/// List of attachments for a message
@JsonSerializable()
class MessageAttachmentsResponse {
  final List<AttachmentMetadata> attachments;

  const MessageAttachmentsResponse({
    required this.attachments,
  });

  factory MessageAttachmentsResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageAttachmentsResponseToJson(this);
}

/// Local pending attachment (before upload completes)
class PendingAttachment {
  final String localId;
  final String filePath; // Used for mobile; on web this may be a blob URL
  final String fileName;
  final String mimeType;
  final int fileSize;
  final int? width;
  final int? height;
  final AttachmentUploadStatus status;
  final String? attachmentId; // Set after successful upload
  final String? errorMessage;
  final double uploadProgress;
  final Uint8List? bytes; // For web - store file bytes directly
  final XFile? xFile; // Reference to original XFile for reading bytes

  const PendingAttachment({
    required this.localId,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.width,
    this.height,
    this.status = AttachmentUploadStatus.pending,
    this.attachmentId,
    this.errorMessage,
    this.uploadProgress = 0.0,
    this.bytes,
    this.xFile,
  });

  PendingAttachment copyWith({
    String? localId,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    AttachmentUploadStatus? status,
    String? attachmentId,
    String? errorMessage,
    double? uploadProgress,
    Uint8List? bytes,
    XFile? xFile,
  }) {
    return PendingAttachment(
      localId: localId ?? this.localId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      status: status ?? this.status,
      attachmentId: attachmentId ?? this.attachmentId,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      bytes: bytes ?? this.bytes,
      xFile: xFile ?? this.xFile,
    );
  }

  bool get isUploading => status == AttachmentUploadStatus.uploading;
  bool get isUploaded => status == AttachmentUploadStatus.uploaded;
  bool get hasError => status == AttachmentUploadStatus.error;
  bool get isImage => mimeType.startsWith('image/');
}

enum AttachmentUploadStatus {
  pending,
  uploading,
  uploaded,
  error,
}

/// Chat attachment reference (for messages with attachments)
class ChatAttachment {
  final String attachmentId;
  final String? localPath; // For local preview before/during upload
  final String? url; // Signed URL for display
  final String fileName;
  final String contentType;
  final int? width;
  final int? height;
  final DateTime? urlExpiresAt;
  final Uint8List? bytes; // For web - store bytes for local preview

  const ChatAttachment({
    required this.attachmentId,
    this.localPath,
    this.url,
    required this.fileName,
    required this.contentType,
    this.width,
    this.height,
    this.urlExpiresAt,
    this.bytes,
  });

  ChatAttachment copyWith({
    String? attachmentId,
    String? localPath,
    String? url,
    String? fileName,
    String? contentType,
    int? width,
    int? height,
    DateTime? urlExpiresAt,
    Uint8List? bytes,
  }) {
    return ChatAttachment(
      attachmentId: attachmentId ?? this.attachmentId,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      width: width ?? this.width,
      height: height ?? this.height,
      urlExpiresAt: urlExpiresAt ?? this.urlExpiresAt,
      bytes: bytes ?? this.bytes,
    );
  }

  bool get isImage => contentType.startsWith('image/');

  bool get isUrlExpired {
    if (urlExpiresAt == null) return true;
    return DateTime.now().isAfter(urlExpiresAt!);
  }

  /// Get the best available image source (local path or URL)
  String? get displaySource => localPath ?? url;

  /// Check if we have bytes for local preview (web)
  bool get hasLocalBytes => bytes != null && bytes!.isNotEmpty;
}
