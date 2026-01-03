/// Model for agent voice settings

/// Agent information for display
class AgentInfo {
  final String id;
  final String displayName;
  final String description;

  const AgentInfo({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Available agents in the system
  static const List<AgentInfo> availableAgents = [
    AgentInfo(
      id: 'primary_agent',
      displayName: 'Primary Agent',
      description: 'Main assistant that handles conversations',
    ),
    AgentInfo(
      id: 'weather_agent',
      displayName: 'Weather Agent',
      description: 'Provides weather information and forecasts',
    ),
    AgentInfo(
      id: 'calendar_agent',
      displayName: 'Calendar Agent',
      description: 'Manages events and reminders',
    ),
    AgentInfo(
      id: 'notes_agent',
      displayName: 'Notes Agent',
      description: 'Creates and manages notes',
    ),
    AgentInfo(
      id: 'calculator_agent',
      displayName: 'Calculator Agent',
      description: 'Performs mathematical calculations',
    ),
    AgentInfo(
      id: 'search_agent',
      displayName: 'Search Agent',
      description: 'Searches the web for information',
    ),
    AgentInfo(
      id: 'browser_agent',
      displayName: 'Browser Agent',
      description: 'Browses and interacts with websites',
    ),
  ];

  static AgentInfo? getAgent(String id) {
    try {
      return availableAgents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Voice setting for a single agent
class AgentVoiceSetting {
  final String agentId;
  final String ttsProvider;
  final String voiceId;
  final String? voiceName;
  final bool isCustom;

  const AgentVoiceSetting({
    required this.agentId,
    required this.ttsProvider,
    required this.voiceId,
    this.voiceName,
    this.isCustom = false,
  });

  factory AgentVoiceSetting.fromJson(Map<String, dynamic> json) {
    return AgentVoiceSetting(
      agentId: json['agent_id'] as String,
      ttsProvider: json['tts_provider'] as String,
      voiceId: json['voice_id'] as String,
      voiceName: json['voice_name'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'tts_provider': ttsProvider,
      'voice_id': voiceId,
      'voice_name': voiceName,
    };
  }

  AgentVoiceSetting copyWith({
    String? agentId,
    String? ttsProvider,
    String? voiceId,
    String? voiceName,
    bool? isCustom,
  }) {
    return AgentVoiceSetting(
      agentId: agentId ?? this.agentId,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      voiceId: voiceId ?? this.voiceId,
      voiceName: voiceName ?? this.voiceName,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Default voice for an agent (system-wide)
class AgentDefaultVoice {
  final String agentId;
  final String ttsProvider;
  final String voiceId;
  final String? voiceName;
  final String? description;

  const AgentDefaultVoice({
    required this.agentId,
    required this.ttsProvider,
    required this.voiceId,
    this.voiceName,
    this.description,
  });

  factory AgentDefaultVoice.fromJson(Map<String, dynamic> json) {
    return AgentDefaultVoice(
      agentId: json['agent_id'] as String,
      ttsProvider: json['tts_provider'] as String,
      voiceId: json['voice_id'] as String,
      voiceName: json['voice_name'] as String?,
      description: json['description'] as String?,
    );
  }
}
