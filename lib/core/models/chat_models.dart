import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

// VOS API Models

// WebSocket Models

@JsonSerializable()
class WebSocketMessage {
  final String type;
  final dynamic data;

  const WebSocketMessage({
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) =>
      _$WebSocketMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WebSocketMessageToJson(this);
}

@JsonSerializable()
class WebSocketConnectedData {
  @JsonKey(name: 'session_id')
  final String sessionId;
  final String? message;
  @JsonKey(name: 'pending_notifications')
  final int pendingNotifications;

  const WebSocketConnectedData({
    required this.sessionId,
    this.message,
    this.pendingNotifications = 0,
  });

  factory WebSocketConnectedData.fromJson(Map<String, dynamic> json) =>
      _$WebSocketConnectedDataFromJson(json);

  Map<String, dynamic> toJson() => _$WebSocketConnectedDataToJson(this);
}

@JsonSerializable()
class WebSocketNotification {
  @JsonKey(name: 'notification_id')
  final String? notificationId;
  @JsonKey(name: 'notification_type')
  final String notificationType;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'user_id')
  final String? userId;
  final Map<String, dynamic> payload;
  final String timestamp;

  const WebSocketNotification({
    this.notificationId,
    required this.notificationType,
    this.sessionId,
    this.userId,
    required this.payload,
    required this.timestamp,
  });

  factory WebSocketNotification.fromJson(Map<String, dynamic> json) =>
      _$WebSocketNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$WebSocketNotificationToJson(this);
}

@JsonSerializable()
class NewMessagePayload {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'message_id')
  final int? messageId;  // Made nullable to handle missing message_id
  @JsonKey(name: 'agent_id')
  final String agentId;
  final String content;
  @JsonKey(name: 'content_type')
  final String? contentType;
  final String timestamp;
  @JsonKey(name: 'input_mode')
  final String? inputMode; // "text" or "voice"
  @JsonKey(name: 'voice_message_id')
  final int? voiceMessageId;
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'audio_duration_ms')
  final int? audioDurationMs;

  const NewMessagePayload({
    required this.sessionId,
    this.messageId,  // No longer required
    required this.agentId,
    required this.content,
    this.contentType,
    required this.timestamp,
    this.inputMode,
    this.voiceMessageId,
    this.audioFilePath,
    this.audioUrl,
    this.audioDurationMs,
  });

  factory NewMessagePayload.fromJson(Map<String, dynamic> json) =>
      _$NewMessagePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$NewMessagePayloadToJson(this);
}

@JsonSerializable()
class AgentStatusPayload {
  @JsonKey(name: 'agent_id')
  final String agentId;
  final String? status;
  @JsonKey(name: 'processing_state')
  final String? processingState;

  const AgentStatusPayload({
    required this.agentId,
    this.status,
    this.processingState,
  });

  factory AgentStatusPayload.fromJson(Map<String, dynamic> json) =>
      _$AgentStatusPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AgentStatusPayloadToJson(this);
}

@JsonSerializable()
class AgentActionStatusPayload {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'session_id')
  final String? sessionId;  // Nullable for broadcast messages
  @JsonKey(name: 'action_description')
  final String actionDescription;
  final String timestamp;

  const AgentActionStatusPayload({
    required this.agentId,
    this.sessionId,  // Optional for broadcast
    required this.actionDescription,
    required this.timestamp,
  });

  factory AgentActionStatusPayload.fromJson(Map<String, dynamic> json) =>
      _$AgentActionStatusPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AgentActionStatusPayloadToJson(this);
}

@JsonSerializable()
class AppInteractionPayload {
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'app_name')
  final String appName;
  final String action;
  final Map<String, dynamic> result;

  const AppInteractionPayload({
    required this.agentId,
    required this.appName,
    required this.action,
    required this.result,
  });

  factory AppInteractionPayload.fromJson(Map<String, dynamic> json) =>
      _$AppInteractionPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AppInteractionPayloadToJson(this);
}

// HTTP API Models

@JsonSerializable()
class VosMessageRequestDto {
  final String text;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'user_timezone')
  final String? userTimezone;

  const VosMessageRequestDto({
    required this.text,
    this.sessionId,
    this.userTimezone,
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
  final String? timestamp;

  const VosTranscriptMessageDto({
    required this.role,
    required this.content,
    required this.documents,
    this.timestamp,
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

// Conversation API Models (for user-facing conversation messages)

@JsonSerializable()
class ConversationMessageDto {
  final int id;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'sender_type')
  final String senderType; // "user" or "agent"
  @JsonKey(name: 'sender_id')
  final String? senderId;
  final String content;
  final String timestamp;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'input_mode')
  final String? inputMode; // "text" or "voice"
  @JsonKey(name: 'voice_message_id')
  final int? voiceMessageId;
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'audio_duration_ms')
  final int? audioDurationMs;

  const ConversationMessageDto({
    required this.id,
    required this.sessionId,
    required this.senderType,
    this.senderId,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.inputMode,
    this.voiceMessageId,
    this.audioFilePath,
    this.audioUrl,
    this.audioDurationMs,
  });

  factory ConversationMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationMessageDtoToJson(this);
}

@JsonSerializable()
class ConversationHistoryResponseDto {
  @JsonKey(name: 'session_id')
  final String sessionId;
  final List<ConversationMessageDto> messages;
  @JsonKey(name: 'total_messages')
  final int totalMessages;
  final String timestamp;

  const ConversationHistoryResponseDto({
    required this.sessionId,
    required this.messages,
    required this.totalMessages,
    required this.timestamp,
  });

  factory ConversationHistoryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationHistoryResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationHistoryResponseDtoToJson(this);
}

// Session List Models (for listing all available sessions)

@JsonSerializable()
class SessionInfoDto {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'message_count')
  final int messageCount;
  @JsonKey(name: 'last_message_time')
  final String? lastMessageTime;
  @JsonKey(name: 'first_message_time')
  final String? firstMessageTime;
  @JsonKey(name: 'last_message_preview')
  final String? lastMessagePreview;
  @JsonKey(name: 'last_message_sender_type')
  final String? lastMessageSenderType;
  @JsonKey(name: 'last_message_sender_id')
  final String? lastMessageSenderId;

  const SessionInfoDto({
    required this.sessionId,
    required this.messageCount,
    this.lastMessageTime,
    this.firstMessageTime,
    this.lastMessagePreview,
    this.lastMessageSenderType,
    this.lastMessageSenderId,
  });

  factory SessionInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionInfoDtoToJson(this);
}

@JsonSerializable()
class SessionListResponseDto {
  final List<SessionInfoDto> sessions;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  final int limit;
  final int offset;
  final String timestamp;

  const SessionListResponseDto({
    required this.sessions,
    required this.totalSessions,
    required this.limit,
    required this.offset,
    required this.timestamp,
  });

  factory SessionListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SessionListResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionListResponseDtoToJson(this);
}