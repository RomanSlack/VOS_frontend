/// Call-related data models for the VOS call system

/// Call state enum matching backend CallStatus
enum CallState {
  idle,
  ringingOutbound, // User calling agent
  ringingInbound, // Agent calling user
  connected,
  onHold,
  transferring,
  ending,
  ended,
}

/// Call end reasons
enum CallEndReason {
  userHangup,
  agentHangup,
  userDeclined,
  agentDeclined,
  transferComplete,
  timeout,
  error,
  disconnected,
}

/// Represents an active or historical call
class Call {
  final String callId;
  final String sessionId;
  final String initiatedBy; // 'user' or agent_id
  final String initialTarget;
  final String currentAgentId;
  final CallState status;
  final DateTime startedAt;
  final DateTime? ringingAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final CallEndReason? endReason;
  final String? endedBy;
  final Map<String, dynamic> metadata;

  Call({
    required this.callId,
    required this.sessionId,
    required this.initiatedBy,
    required this.initialTarget,
    required this.currentAgentId,
    required this.status,
    required this.startedAt,
    this.ringingAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
    this.endedBy,
    this.metadata = const {},
  });

  /// Get call duration in seconds (null if not connected yet)
  int? get durationSeconds {
    if (connectedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(connectedAt!).inSeconds;
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    final seconds = durationSeconds;
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Whether the call is currently active
  bool get isActive =>
      status == CallState.connected ||
      status == CallState.ringingOutbound ||
      status == CallState.ringingInbound ||
      status == CallState.onHold ||
      status == CallState.transferring;

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      callId: json['call_id'] as String,
      sessionId: json['session_id'] as String,
      initiatedBy: json['initiated_by'] as String,
      initialTarget: json['initial_target'] as String? ?? 'primary_agent',
      currentAgentId: json['current_agent_id'] as String,
      status: _parseCallState(json['status'] as String?),
      // Convert UTC times to local for proper display
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
      ringingAt: json['ringing_at'] != null
          ? DateTime.parse(json['ringing_at'] as String).toLocal()
          : null,
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'] as String).toLocal()
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String).toLocal()
          : null,
      endReason: _parseEndReason(json['end_reason'] as String?),
      endedBy: json['ended_by'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'session_id': sessionId,
      'initiated_by': initiatedBy,
      'initial_target': initialTarget,
      'current_agent_id': currentAgentId,
      'status': status.name,
      'started_at': startedAt.toIso8601String(),
      'ringing_at': ringingAt?.toIso8601String(),
      'connected_at': connectedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'end_reason': endReason?.name,
      'ended_by': endedBy,
      'metadata': metadata,
    };
  }

  static CallState _parseCallState(String? status) {
    switch (status) {
      case 'ringing_outbound':
        return CallState.ringingOutbound;
      case 'ringing_inbound':
        return CallState.ringingInbound;
      case 'connected':
        return CallState.connected;
      case 'on_hold':
        return CallState.onHold;
      case 'transferring':
        return CallState.transferring;
      case 'ending':
        return CallState.ending;
      case 'ended':
        return CallState.ended;
      default:
        return CallState.idle;
    }
  }

  static CallEndReason? _parseEndReason(String? reason) {
    switch (reason) {
      case 'user_hangup':
        return CallEndReason.userHangup;
      case 'agent_hangup':
        return CallEndReason.agentHangup;
      case 'user_declined':
        return CallEndReason.userDeclined;
      case 'agent_declined':
        return CallEndReason.agentDeclined;
      case 'transfer_complete':
        return CallEndReason.transferComplete;
      case 'timeout':
        return CallEndReason.timeout;
      case 'error':
        return CallEndReason.error;
      case 'disconnected':
        return CallEndReason.disconnected;
      default:
        return null;
    }
  }

  Call copyWith({
    String? callId,
    String? sessionId,
    String? initiatedBy,
    String? initialTarget,
    String? currentAgentId,
    CallState? status,
    DateTime? startedAt,
    DateTime? ringingAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    CallEndReason? endReason,
    String? endedBy,
    Map<String, dynamic>? metadata,
  }) {
    return Call(
      callId: callId ?? this.callId,
      sessionId: sessionId ?? this.sessionId,
      initiatedBy: initiatedBy ?? this.initiatedBy,
      initialTarget: initialTarget ?? this.initialTarget,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      ringingAt: ringingAt ?? this.ringingAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
      endedBy: endedBy ?? this.endedBy,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// WebSocket message types for call signaling
class CallEventType {
  static const String callRinging = 'call_ringing';
  static const String callConnected = 'call_connected';
  static const String callEnded = 'call_ended';
  static const String callOnHold = 'call_on_hold';
  static const String callTransferring = 'call_transferring';
  static const String transcription = 'transcription';
  static const String transcriptionInterim = 'transcription_interim';
  static const String transcriptionFinal = 'transcription_final';
  static const String agentSpeaking = 'agent_speaking';
  static const String speakingCompleted = 'speaking_completed';
  static const String error = 'error';
}

/// Incoming call notification payload
class IncomingCallPayload {
  final String callId;
  final String callerAgentId;
  final String reason;
  final DateTime timestamp;

  IncomingCallPayload({
    required this.callId,
    required this.callerAgentId,
    required this.reason,
    required this.timestamp,
  });

  factory IncomingCallPayload.fromJson(Map<String, dynamic> json) {
    return IncomingCallPayload(
      callId: json['call_id'] as String,
      callerAgentId: json['caller_agent_id'] as String? ?? 'primary_agent',
      reason: json['reason'] as String? ?? 'incoming_call',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// Call transcript entry
class CallTranscript {
  final String speakerType; // 'user' or 'agent'
  final String? speakerId;
  final String content;
  final DateTime timestamp;
  final double? confidence;

  CallTranscript({
    required this.speakerType,
    this.speakerId,
    required this.content,
    required this.timestamp,
    this.confidence,
  });

  factory CallTranscript.fromJson(Map<String, dynamic> json) {
    return CallTranscript(
      speakerType: json['speaker_type'] as String,
      speakerId: json['speaker_id'] as String?,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      confidence: json['confidence'] as double?,
    );
  }

  bool get isUser => speakerType == 'user';
  bool get isAgent => speakerType == 'agent';
}

/// Call history item from API
class CallHistoryItem {
  final String callId;
  final String sessionId;
  final String initiatedBy;
  final String initialTarget;
  final String currentAgentId;
  final String callStatus;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final String? endReason;
  final int? durationSeconds;

  CallHistoryItem({
    required this.callId,
    required this.sessionId,
    required this.initiatedBy,
    required this.initialTarget,
    required this.currentAgentId,
    required this.callStatus,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
    this.durationSeconds,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      callId: json['call_id'] as String,
      sessionId: json['session_id'] as String,
      initiatedBy: json['initiated_by'] as String,
      initialTarget: json['initial_target'] as String,
      currentAgentId: json['current_agent_id'] as String,
      callStatus: json['call_status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'] as String).toLocal()
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String).toLocal()
          : null,
      endReason: json['end_reason'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
    );
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final secs = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Whether call was incoming (agent called user)
  bool get wasIncoming => initiatedBy != 'user';

  /// Whether call was answered
  bool get wasAnswered => connectedAt != null;

  /// Whether call was missed (incoming and not answered)
  bool get wasMissed =>
      wasIncoming && !wasAnswered && callStatus == 'ended';
}

/// Call history response from API
class CallHistoryResponse {
  final List<CallHistoryItem> calls;
  final int total;
  final int page;
  final int pageSize;

  CallHistoryResponse({
    required this.calls,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponse(
      calls: (json['calls'] as List)
          .map((e) => CallHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }

  bool get hasMore => calls.length < total;
}
