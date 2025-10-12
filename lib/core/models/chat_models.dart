import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

// VOS API Models

@JsonSerializable()
class VosMessageRequestDto {
  final String text;

  const VosMessageRequestDto({
    required this.text,
  });

  factory VosMessageRequestDto.fromJson(Map<String, dynamic> json) =>
      _$VosMessageRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VosMessageRequestDtoToJson(this);
}

@JsonSerializable()
class VosMessageResponseDto {
  final String status;
  @JsonKey(name: 'notification_id')
  final String notificationId;
  final String recipient;
  final String queue;

  const VosMessageResponseDto({
    required this.status,
    required this.notificationId,
    required this.recipient,
    required this.queue,
  });

  factory VosMessageResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VosMessageResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VosMessageResponseDtoToJson(this);
}

@JsonSerializable()
class VosTranscriptMessageContentDto {
  final String text;

  const VosTranscriptMessageContentDto({
    required this.text,
  });

  factory VosTranscriptMessageContentDto.fromJson(Map<String, dynamic> json) =>
      _$VosTranscriptMessageContentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VosTranscriptMessageContentDtoToJson(this);
}

@JsonSerializable()
class VosTranscriptMessageDto {
  final String role;
  final VosTranscriptMessageContentDto content;
  final List<dynamic> documents;

  const VosTranscriptMessageDto({
    required this.role,
    required this.content,
    required this.documents,
  });

  factory VosTranscriptMessageDto.fromJson(Map<String, dynamic> json) =>
      _$VosTranscriptMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VosTranscriptMessageDtoToJson(this);
}

@JsonSerializable()
class VosTranscriptResponseDto {
  @JsonKey(name: 'agent_id')
  final String agentId;
  final List<VosTranscriptMessageDto> messages;
  @JsonKey(name: 'total_messages')
  final int totalMessages;
  final String timestamp;

  const VosTranscriptResponseDto({
    required this.agentId,
    required this.messages,
    required this.totalMessages,
    required this.timestamp,
  });

  factory VosTranscriptResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VosTranscriptResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VosTranscriptResponseDtoToJson(this);
}