import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:vos_app/features/voice/widgets/voice_chat_widget.dart';

/// Test page for voice mode integration
/// This demonstrates how to use the VoiceChatWidget
class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  late final String sessionId;

  @override
  void initState() {
    super.initState();
    // Generate a unique session ID for this voice session
    sessionId = const Uuid().v4();
    debugPrint('🎙️ Voice test page initialized with session: $sessionId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Mode Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Test Instructions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Tap the microphone button to start listening\n'
                        '2. Speak clearly into your microphone\n'
                        '3. Watch for live transcription\n'
                        '4. Agent will process and respond\n'
                        '5. Listen to TTS audio response\n\n'
                        'Session ID: ',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        sessionId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: VoiceChatWidget(sessionId: sessionId),
            ),
          ],
        ),
      ),
    );
  }
}
