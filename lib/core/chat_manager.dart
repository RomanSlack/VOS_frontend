import 'package:flutter/material.dart';

enum AgentProcessingState {
  idle,
  thinking,
  executingTools,
}

class ChatManager extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  AgentProcessingState _agentState = AgentProcessingState.idle;
  String? _actionDescription;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasMessages => _messages.isNotEmpty;
  AgentProcessingState get agentState => _agentState;
  String? get actionDescription => _actionDescription;
  bool get isAgentWorking => _agentState != AgentProcessingState.idle;

  ChatManager() {
    // Start with empty messages - will be loaded from conversation history
  }

  void addMessage(String text, bool isUser) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _agentState = AgentProcessingState.idle;
    _actionDescription = null;
    notifyListeners();
  }

  void loadMessages(List<ChatMessage> messages) {
    _messages.clear();
    _messages.addAll(messages);
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}