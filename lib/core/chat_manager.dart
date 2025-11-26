import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vos_app/core/models/attachment_models.dart';
import 'package:vos_app/core/models/document_models.dart';

enum AgentProcessingState {
  idle,
  thinking,
  executingTools,
}

enum MessageStatus {
  sending,     // Optimistic update - message being sent
  sent,        // Successfully sent to server
  error,       // Failed to send
  received,    // Received from server (for AI messages)
}

class ChatManager extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  AgentProcessingState _agentState = AgentProcessingState.idle;
  String? _actionDescription;
  bool _isConnected = true; // WebSocket connection status
  int _lastReadIndex = -1;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasMessages => _messages.isNotEmpty;
  AgentProcessingState get agentState => _agentState;
  String? get actionDescription => _actionDescription;
  bool get isAgentWorking => _agentState != AgentProcessingState.idle;
  bool get isConnected => _isConnected;

  int get unreadCount {
    if (_lastReadIndex < 0) return 0;
    return _messages.length - _lastReadIndex - 1;
  }

  ChatManager() {
    // Start with empty messages - will be loaded from conversation history
  }

  void addMessage(
    String text,
    bool isUser, {
    String inputMode = 'text',
    int? voiceMessageId,
    String? audioFilePath,
    int? audioDurationMs,
    List<ChatAttachment>? attachments,
    List<Document>? documents,
  }) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      status: MessageStatus.received,
      inputMode: inputMode,
      voiceMessageId: voiceMessageId,
      audioFilePath: audioFilePath,
      audioDurationMs: audioDurationMs,
      attachments: attachments,
      documents: documents,
    ));
    notifyListeners();
  }

  // Add optimistic message (user message before server confirmation)
  String addOptimisticMessage(
    String text, {
    String inputMode = 'text',
    VoiceMetadata? voiceMetadata,
    List<ChatAttachment>? attachments,
  }) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      inputMode: inputMode,
      voiceMetadata: voiceMetadata,
      attachments: attachments,
    );
    _messages.add(message);
    notifyListeners();
    return message.id;
  }

  // Update message status after server response
  void updateMessageStatus(String messageId, MessageStatus status, {String? errorMessage}) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        status: status,
        errorMessage: errorMessage,
      );
      notifyListeners();
    }
  }

  // Attach audio file to the most recent AI message
  void attachAudioToLatestAIMessage(String audioFilePath, {int? audioDurationMs}) {
    // Find the last AI message
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser && _messages[i].audioFilePath == null) {
        _messages[i] = _messages[i].copyWith(
          audioFilePath: audioFilePath,
          audioDurationMs: audioDurationMs,
        );
        notifyListeners();
        return;
      }
    }
  }

  // Update connection status
  void setConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _agentState = AgentProcessingState.idle;
    _actionDescription = null;
    _lastReadIndex = -1;
    notifyListeners();
  }

  void loadMessages(List<ChatMessage> messages, {List<ChatMessage>? pendingMessages}) {
    _messages.clear();
    _messages.addAll(messages);

    // Append pending messages that aren't duplicates
    if (pendingMessages != null) {
      for (final pendingMsg in pendingMessages) {
        final isDuplicate = _messages.any((m) =>
          m.text == pendingMsg.text &&
          m.isUser == pendingMsg.isUser &&
          m.timestamp.difference(pendingMsg.timestamp).abs().inSeconds < 5
        );

        if (!isDuplicate) {
          _messages.add(pendingMsg);
        }
      }
    }

    notifyListeners();
  }

  void updateAgentState(String? processingState, String? actionDescription) {
    if (processingState != null) {
      switch (processingState.toLowerCase()) {
        case 'thinking':
          _agentState = AgentProcessingState.thinking;
          break;
        case 'executing_tools':
          _agentState = AgentProcessingState.executingTools;
          break;
        case 'idle':
        default:
          _agentState = AgentProcessingState.idle;
          break;
      }
    }

    if (actionDescription != null) {
      _actionDescription = actionDescription;
    }

    notifyListeners();
  }

  void setAgentIdle() {
    _agentState = AgentProcessingState.idle;
    _actionDescription = null;
    notifyListeners();
  }

  void markAsRead() {
    _lastReadIndex = _messages.length - 1;
    notifyListeners();
  }

  // Called when user opens chat or scrolls to bottom
  void updateLastReadPosition(int index) {
    if (index > _lastReadIndex) {
      _lastReadIndex = index;
      notifyListeners();
    }
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final String inputMode; // 'text' or 'voice'
  final VoiceMetadata? voiceMetadata;
  final int? voiceMessageId; // Backend voice message ID
  final String? audioFilePath; // For AI voice responses (relative path from backend)
  final int? audioDurationMs; // Audio duration in milliseconds
  final List<ChatAttachment>? attachments; // Image/file attachments
  final List<Document>? documents; // Document references

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.received,
    this.errorMessage,
    this.inputMode = 'text',
    this.voiceMetadata,
    this.voiceMessageId,
    this.audioFilePath,
    this.audioDurationMs,
    this.attachments,
    this.documents,
  }) : id = id ?? const Uuid().v4();

  // Check if message has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  // Check if message has documents
  bool get hasDocuments => documents != null && documents!.isNotEmpty;

  // Get image attachments only
  List<ChatAttachment> get imageAttachments =>
      attachments?.where((a) => a.isImage).toList() ?? [];

  // Add copyWith for status updates
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
    String? inputMode,
    VoiceMetadata? voiceMetadata,
    int? voiceMessageId,
    String? audioFilePath,
    int? audioDurationMs,
    List<ChatAttachment>? attachments,
    List<Document>? documents,
  }) {
    return ChatMessage(
      id: this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      inputMode: inputMode ?? this.inputMode,
      voiceMetadata: voiceMetadata ?? this.voiceMetadata,
      voiceMessageId: voiceMessageId ?? this.voiceMessageId,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      attachments: attachments ?? this.attachments,
      documents: documents ?? this.documents,
    );
  }
}

class VoiceMetadata {
  final String? sessionId;
  final double? confidence;
  final int? audioDurationMs;
  final String? model;

  const VoiceMetadata({
    this.sessionId,
    this.confidence,
    this.audioDurationMs,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      if (confidence != null) 'transcription_confidence': confidence,
      if (audioDurationMs != null) 'audio_duration_ms': audioDurationMs,
      if (model != null) 'model': model,
    };
  }
}
