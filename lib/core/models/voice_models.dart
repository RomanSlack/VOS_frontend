import 'package:json_annotation/json_annotation.dart';

part 'voice_models.g.dart';

/// Voice interaction state machine
enum VoiceState {
  /// Not connected or inactive
  idle,

  /// Recording user audio and sending to server
  listening,

  /// Agent is processing the request
  processing,

  /// Agent is speaking (playing TTS audio)
  speaking,

  /// Error state
  error,
}

/// Voice WebSocket message types
enum VoiceMessageType {
  // Client → Server
  startSession,
  endSession,
  // audioChunk is sent as binary, not JSON

  // Server → Client
  sessionStarted,
  listeningStarted,
  transcriptionInterim,
  transcriptionFinal,
  agentThinking,
  speakingStarted,
  speakingCompleted,
  error,
}

/// Base voice WebSocket message structure
@JsonSerializable()
class VoiceMessage {
  final String type;
  final Map<String, dynamic> payload;

  const VoiceMessage({
    required this.type,
    required this.payload,
  });

  factory VoiceMessage.fromJson(Map<String, dynamic> json) =>
      _$VoiceMessageFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMessageToJson(this);
}

/// Audio format configuration
@JsonSerializable()
class AudioFormat {
  final String codec;
  final String container;
  @JsonKey(name: 'sample_rate')
  final int sampleRate;
  final int channels;
  final int? bitrate;

  const AudioFormat({
    required this.codec,
    required this.container,
    required this.sampleRate,
    required this.channels,
    this.bitrate,
  });

  factory AudioFormat.fromJson(Map<String, dynamic> json) =>
      _$AudioFormatFromJson(json);

  Map<String, dynamic> toJson() => _$AudioFormatToJson(this);

  /// Default audio format for web (PCM 16-bit)
  static const AudioFormat webDefault = AudioFormat(
    codec: 'pcm',
    container: 'wav',
    sampleRate: 16000,
    channels: 1,
    bitrate: 128000, // Max allowed by backend
  );
}

/// Start session message payload
@JsonSerializable()
class StartSessionPayload {
  final String platform;
  @JsonKey(name: 'audio_format')
  final AudioFormat audioFormat;
  final String language;
  @JsonKey(name: 'voice_preference')
  final String voicePreference;
  @JsonKey(name: 'endpointing_ms')
  final int? endpointingMs;
  @JsonKey(name: 'user_timezone')
  final String? userTimezone;

  const StartSessionPayload({
    required this.platform,
    required this.audioFormat,
    required this.language,
    required this.voicePreference,
    this.endpointingMs,
    this.userTimezone,
  });

  factory StartSessionPayload.fromJson(Map<String, dynamic> json) =>
      _$StartSessionPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$StartSessionPayloadToJson(this);

  /// Create default payload for web platform
  static StartSessionPayload webDefault({String? userTimezone}) =>
      StartSessionPayload(
        platform: 'web',
        audioFormat: AudioFormat.webDefault,
        language: 'en',
        voicePreference: 'default',
        endpointingMs: null, // Disable automatic endpointing by default
        userTimezone: userTimezone,
      );

  /// Create payload with custom endpointing setting
  static StartSessionPayload webWithEndpointing(
    int? endpointingMs, {
    String? userTimezone,
  }) =>
      StartSessionPayload(
        platform: 'web',
        audioFormat: AudioFormat.webDefault,
        language: 'en',
        voicePreference: 'default',
        endpointingMs: endpointingMs,
        userTimezone: userTimezone,
      );
}

/// Session started response payload
@JsonSerializable()
class SessionStartedPayload {
  @JsonKey(name: 'session_id')
  final String sessionId;
  final String timestamp;

  const SessionStartedPayload({
    required this.sessionId,
    required this.timestamp,
  });

  factory SessionStartedPayload.fromJson(Map<String, dynamic> json) =>
      _$SessionStartedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStartedPayloadToJson(this);
}

/// Listening started response payload
@JsonSerializable()
class ListeningStartedPayload {
  final String timestamp;

  const ListeningStartedPayload({
    required this.timestamp,
  });

  factory ListeningStartedPayload.fromJson(Map<String, dynamic> json) =>
      _$ListeningStartedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ListeningStartedPayloadToJson(this);
}

/// Transcription result (interim or final)
@JsonSerializable()
class TranscriptionPayload {
  final String text;
  @JsonKey(name: 'is_final')
  final bool isFinal;
  final double confidence;

  const TranscriptionPayload({
    required this.text,
    required this.isFinal,
    required this.confidence,
  });

  factory TranscriptionPayload.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionPayloadToJson(this);
}

/// Agent thinking status payload
@JsonSerializable()
class AgentThinkingPayload {
  final String status;

  const AgentThinkingPayload({
    required this.status,
  });

  factory AgentThinkingPayload.fromJson(Map<String, dynamic> json) =>
      _$AgentThinkingPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AgentThinkingPayloadToJson(this);
}

/// Speaking started payload
@JsonSerializable()
class SpeakingStartedPayload {
  final String text;
  @JsonKey(name: 'estimated_duration_ms')
  final int estimatedDurationMs;

  const SpeakingStartedPayload({
    required this.text,
    required this.estimatedDurationMs,
  });

  factory SpeakingStartedPayload.fromJson(Map<String, dynamic> json) =>
      _$SpeakingStartedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakingStartedPayloadToJson(this);
}

/// Speaking completed payload
@JsonSerializable()
class SpeakingCompletedPayload {
  final String timestamp;
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'audio_duration_ms')
  final int? audioDurationMs;

  const SpeakingCompletedPayload({
    required this.timestamp,
    this.audioFilePath,
    this.audioUrl,
    this.audioDurationMs,
  });

  factory SpeakingCompletedPayload.fromJson(Map<String, dynamic> json) =>
      _$SpeakingCompletedPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakingCompletedPayloadToJson(this);
}

/// Voice error payload
@JsonSerializable()
class VoiceErrorPayload {
  final String code;
  final String message;
  final String severity;

  const VoiceErrorPayload({
    required this.code,
    required this.message,
    required this.severity,
  });

  factory VoiceErrorPayload.fromJson(Map<String, dynamic> json) =>
      _$VoiceErrorPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceErrorPayloadToJson(this);
}

/// Voice token request payload
@JsonSerializable()
class VoiceTokenRequest {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'user_id')
  final String? userId;

  const VoiceTokenRequest({
    required this.sessionId,
    this.userId,
  });

  factory VoiceTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$VoiceTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTokenRequestToJson(this);
}

/// Voice token response from backend
@JsonSerializable()
class VoiceTokenResponse {
  final String token;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'expires_in_minutes')
  final int expiresInMinutes;
  @JsonKey(name: 'websocket_url')
  final String websocketUrl;

  const VoiceTokenResponse({
    required this.token,
    required this.sessionId,
    required this.expiresInMinutes,
    required this.websocketUrl,
  });

  factory VoiceTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$VoiceTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTokenResponseToJson(this);
}

/// Audio received payload (for TTS playback)
class AudioReceivedPayload {
  final String audioUrl; // Full URL to audio file
  final int? durationMs; // Audio duration in milliseconds
  final String timestamp;

  const AudioReceivedPayload({
    required this.audioUrl,
    this.durationMs,
    required this.timestamp,
  });
}

/// Batch transcription job status
enum BatchTranscriptionStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Batch transcription job response (after file upload)
@JsonSerializable()
class BatchTranscriptionJob {
  @JsonKey(name: 'job_id')
  final String jobId;
  final String status;
  final String filename;

  const BatchTranscriptionJob({
    required this.jobId,
    required this.status,
    required this.filename,
  });

  factory BatchTranscriptionJob.fromJson(Map<String, dynamic> json) =>
      _$BatchTranscriptionJobFromJson(json);

  Map<String, dynamic> toJson() => _$BatchTranscriptionJobToJson(this);

  BatchTranscriptionStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'pending':
        return BatchTranscriptionStatus.pending;
      case 'processing':
        return BatchTranscriptionStatus.processing;
      case 'completed':
        return BatchTranscriptionStatus.completed;
      case 'failed':
        return BatchTranscriptionStatus.failed;
      default:
        return BatchTranscriptionStatus.pending;
    }
  }
}

/// Batch transcription job status check response
@JsonSerializable()
class BatchTranscriptionStatusResponse {
  @JsonKey(name: 'job_id')
  final String jobId;
  final String status;
  final String filename;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  final String? error;

  const BatchTranscriptionStatusResponse({
    required this.jobId,
    required this.status,
    required this.filename,
    this.createdAt,
    this.completedAt,
    this.error,
  });

  factory BatchTranscriptionStatusResponse.fromJson(
          Map<String, dynamic> json) =>
      _$BatchTranscriptionStatusResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$BatchTranscriptionStatusResponseToJson(this);

  BatchTranscriptionStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'pending':
        return BatchTranscriptionStatus.pending;
      case 'processing':
        return BatchTranscriptionStatus.processing;
      case 'completed':
        return BatchTranscriptionStatus.completed;
      case 'failed':
        return BatchTranscriptionStatus.failed;
      default:
        return BatchTranscriptionStatus.pending;
    }
  }
}

/// Utterance from speaker diarization
@JsonSerializable()
class TranscriptionUtterance {
  final String speaker;
  final String text;
  final int start;
  final int end;
  final double confidence;

  const TranscriptionUtterance({
    required this.speaker,
    required this.text,
    required this.start,
    required this.end,
    required this.confidence,
  });

  factory TranscriptionUtterance.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionUtteranceFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionUtteranceToJson(this);
}

/// Batch transcription result response
@JsonSerializable()
class BatchTranscriptionResult {
  @JsonKey(name: 'job_id')
  final String jobId;
  final String status;
  final String? text;
  final double? confidence;
  @JsonKey(name: 'audio_duration')
  final double? audioDuration; // Duration in seconds
  final List<TranscriptionUtterance>? utterances;
  final String? error;

  const BatchTranscriptionResult({
    required this.jobId,
    required this.status,
    this.text,
    this.confidence,
    this.audioDuration,
    this.utterances,
    this.error,
  });

  factory BatchTranscriptionResult.fromJson(Map<String, dynamic> json) =>
      _$BatchTranscriptionResultFromJson(json);

  Map<String, dynamic> toJson() => _$BatchTranscriptionResultToJson(this);
}
