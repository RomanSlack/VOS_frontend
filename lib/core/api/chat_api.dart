import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/chat_models.dart';

part 'chat_api.g.dart';

@RestApi(baseUrl: 'http://localhost:5555')
abstract class ChatApi {
  factory ChatApi(Dio dio) = _ChatApi;

  @POST('/chat/completions')
  Future<ChatResponseDto> chatCompletions(@Body() ChatRequestDto request);
}