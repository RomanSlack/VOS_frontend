import 'package:flutter/material.dart';

class ChatManager extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasMessages => _messages.isNotEmpty;

  ChatManager() {
    // Add initial greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
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
    // Add back the initial greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
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