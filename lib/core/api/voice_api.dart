import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/voice_models.dart';

part 'voice_api.g.dart';

@RestApi(baseUrl: '')
abstract class VoiceApi {
  factory VoiceApi(Dio dio, {String? baseUrl}) = _VoiceApi;

  /// Request JWT token for voice WebSocket authentication
  @POST('/voice/token')
  Future<VoiceTokenResponse> getVoiceToken(@Query('session_id') String sessionId);

  /// Upload audio file for batch transcription
  @POST('/api/v1/transcription/upload')
  @MultiPart()
  Future<BatchTranscriptionJob> uploadAudioForTranscription(
    @Part(name: 'file') File file,
    @Header('Authorization') String authorization,
  );

  /// Check batch transcription job status
  @GET('/api/v1/transcription/{job_id}')
  Future<BatchTranscriptionStatusResponse> getTranscriptionStatus(
    @Path('job_id') String jobId,
    @Header('Authorization') String authorization,
  );

  /// Get batch transcription result
  @GET('/api/v1/transcription/{job_id}/result')
  Future<BatchTranscriptionResult> getTranscriptionResult(
    @Path('job_id') String jobId,
    @Header('Authorization') String authorization,
  );
}
