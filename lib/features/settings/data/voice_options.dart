/// Voice option model for TTS provider voices
class VoiceOption {
  final String id;
  final String name;
  final String? description;

  const VoiceOption({
    required this.id,
    required this.name,
    this.description,
  });
}

/// TTS provider configuration
class TtsProvider {
  final String id;
  final String name;
  final List<VoiceOption> voices;

  const TtsProvider({
    required this.id,
    required this.name,
    required this.voices,
  });
}

/// Available TTS providers with their popular voices
class VoiceOptions {
  /// Custom voice ID placeholder
  static const String customVoiceId = 'custom';

  /// Cartesia TTS provider with popular voices
  static const TtsProvider cartesia = TtsProvider(
    id: 'cartesia',
    name: 'Cartesia',
    voices: [
      VoiceOption(
        id: '79a125e8-cd45-4c13-8a67-188112f4dd22',
        name: 'British Lady',
        description: 'Professional British female voice',
      ),
      VoiceOption(
        id: 'a0e99841-438c-4a64-b679-ae501e7d6091',
        name: 'Barbershop Man',
        description: 'Warm male voice',
      ),
      VoiceOption(
        id: '638efaaa-4d0c-442e-b701-3fae16aad012',
        name: 'Sarah',
        description: 'Natural conversational female',
      ),
      VoiceOption(
        id: '87748186-23bb-4f5d-8c71-d4e8e31c2e55',
        name: 'Madame Mischief',
        description: 'Playful female voice',
      ),
      VoiceOption(
        id: '95856005-0332-41b0-935f-352e296aa0df',
        name: 'Classy British Man',
        description: 'Refined British male voice',
      ),
      VoiceOption(
        id: 'f9836c6e-a0bd-460e-9d3c-f7299fa60f94',
        name: 'Yogaman',
        description: 'Calm, soothing male voice',
      ),
      VoiceOption(
        id: '421b3369-f63f-4b03-8980-37a44df1d4e8',
        name: 'Vampire',
        description: 'Deep, mysterious male voice',
      ),
      VoiceOption(
        id: '156fb8d2-335b-4950-9cb3-a2d33f2c7a9e',
        name: 'Newsman',
        description: 'Clear, professional news anchor',
      ),
    ],
  );

  /// ElevenLabs TTS provider with popular voices
  static const TtsProvider elevenlabs = TtsProvider(
    id: 'elevenlabs',
    name: 'ElevenLabs',
    voices: [
      VoiceOption(
        id: '21m00Tcm4TlvDq8ikWAM',
        name: 'Rachel',
        description: 'Calm, clear female voice',
      ),
      VoiceOption(
        id: 'AZnzlk1XvdvUeBnXmlld',
        name: 'Domi',
        description: 'Strong, confident female',
      ),
      VoiceOption(
        id: 'EXAVITQu4vr4xnSDxMaL',
        name: 'Bella',
        description: 'Soft, gentle female voice',
      ),
      VoiceOption(
        id: 'ErXwobaYiN019PkySvjV',
        name: 'Antoni',
        description: 'Well-rounded male voice',
      ),
      VoiceOption(
        id: 'MF3mGyEYCl7XYWbV9V6O',
        name: 'Elli',
        description: 'Youthful female voice',
      ),
      VoiceOption(
        id: 'TxGEqnHWrfWFTfGW9XjX',
        name: 'Josh',
        description: 'Deep, authoritative male',
      ),
      VoiceOption(
        id: 'VR6AewLTigWG4xSOukaG',
        name: 'Arnold',
        description: 'Crisp, clear male voice',
      ),
      VoiceOption(
        id: 'pNInz6obpgDQGcFmaJgB',
        name: 'Adam',
        description: 'Deep, narrative male voice',
      ),
      VoiceOption(
        id: 'yoZ06aMxZJJ28mfd3POQ',
        name: 'Sam',
        description: 'Raspy, dynamic male voice',
      ),
    ],
  );

  /// All available providers
  static const List<TtsProvider> providers = [cartesia, elevenlabs];

  /// Get provider by ID
  static TtsProvider? getProvider(String id) {
    try {
      return providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get voice by provider and voice ID
  static VoiceOption? getVoice(String providerId, String voiceId) {
    final provider = getProvider(providerId);
    if (provider == null) return null;
    try {
      return provider.voices.firstWhere((v) => v.id == voiceId);
    } catch (_) {
      return null;
    }
  }

  /// Get default voice for a provider
  static VoiceOption? getDefaultVoice(String providerId) {
    final provider = getProvider(providerId);
    if (provider == null || provider.voices.isEmpty) return null;
    return provider.voices.first;
  }
}
