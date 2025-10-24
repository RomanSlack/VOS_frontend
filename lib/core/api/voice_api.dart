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
}
