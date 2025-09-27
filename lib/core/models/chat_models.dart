import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class ChatMessageDto {
  final String role;
  final String content;

  const ChatMessageDto({
    required this.role,
    required this.content,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);
}

@JsonSerializable()
class ChatRequestDto {
  final List<ChatMessageDto> messages;
  final String model;
  @JsonKey(name: 'max_tokens')
  final int maxTokens;
  final double temperature;

  const ChatRequestDto({
    required this.messages,
    this.model = 'gpt-3.5-turbo',
    this.maxTokens = 1000,
    this.temperature = 0.7,
  });

  factory ChatRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRequestDtoToJson(this);
}

@JsonSerializable()
class ChatUsageDto {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  const ChatUsageDto({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory ChatUsageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatUsageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatUsageDtoToJson(this);
}

@JsonSerializable()
class ChatResponseDto {
  final String message;
  final String model;
  final ChatUsageDto usage;

  const ChatResponseDto({
    required this.message,
    required this.model,
    required this.usage,
  });

  factory ChatResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ChatResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatResponseDtoToJson(this);
}