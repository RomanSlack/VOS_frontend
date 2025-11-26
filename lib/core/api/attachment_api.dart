import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:http_parser/http_parser.dart';
import 'package:vos_app/core/models/attachment_models.dart';

part 'attachment_api.g.dart';

@RestApi(baseUrl: '')
abstract class AttachmentApi {
  factory AttachmentApi(Dio dio, {String? baseUrl}) = _AttachmentApi;

  /// Get attachment metadata
  @GET('/api/v1/attachments/{attachment_id}')
  Future<AttachmentMetadata> getAttachment(
    @Path('attachment_id') String attachmentId,
  );

  /// Get signed URL for viewing/downloading
  @GET('/api/v1/attachments/{attachment_id}/url')
  Future<AttachmentUrlResponse> getAttachmentUrl(
    @Path('attachment_id') String attachmentId,
  );

  /// Get all attachments for a message
  @GET('/api/v1/attachments/message/{message_id}')
  Future<MessageAttachmentsResponse> getMessageAttachments(
    @Path('message_id') String messageId,
  );
}

/// Extension methods for AttachmentApi to handle custom upload with progress
extension AttachmentApiExtension on Dio {
  /// Upload attachment with progress callback (works on web and mobile)
  Future<AttachmentUploadResponse> uploadAttachmentWithProgress(
    dynamic fileData, // Can be File on mobile or XFile on web
    String sessionId,
    String fileName,
    String? mimeType, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final resolvedMimeType = mimeType ?? _getMimeType(fileName);

    MultipartFile multipartFile;

    if (fileData is List<int>) {
      // Bytes (web)
      multipartFile = MultipartFile.fromBytes(
        fileData,
        filename: fileName,
        contentType: resolvedMimeType != null ? MediaType.parse(resolvedMimeType) : null,
      );
    } else {
      // File path (mobile) - fileData should be the path string
      multipartFile = await MultipartFile.fromFile(
        fileData.toString(),
        filename: fileName,
        contentType: resolvedMimeType != null ? MediaType.parse(resolvedMimeType) : null,
      );
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'session_id': sessionId, // Backend expects session_id as form field
    });

    final response = await post(
      '/api/v1/attachments/upload',
      data: formData,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );

    // Debug: Log the actual response
    // ignore: avoid_print
    print('📤 Upload response type: ${response.data.runtimeType}');
    // ignore: avoid_print
    print('📤 Upload response: ${response.data}');

    return AttachmentUploadResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get the MIME type from file extension
  static String? _getMimeType(String fileName) {
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
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return null;
    }
  }
}
