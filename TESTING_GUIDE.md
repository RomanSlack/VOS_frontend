# Voice Mode Testing Guide 🎙️

## ✅ Project Ready

The project has been cleaned, rebuilt, and verified. Voice mode is ready to test!

---

## Quick Start (3 Steps)

### Step 1: Start the Backend

Ensure your voice gateway backend is running:
```bash
# Should be running at:
# - Local: ws://localhost:8100/ws/voice/{sessionId}
# - Production: wss://api.jarvos.dev/ws/voice/{sessionId}
```

### Step 2: Run the Flutter App

```bash
cd C:\Users\forke\Documents\VOS_frontend
flutter run -d chrome
```

### Step 3: Navigate to Voice Test Page

In the browser, navigate to:
```
http://localhost:PORT/voice-test
```

Or programmatically:
```dart
context.go('/voice-test');
// or
context.goNamed(AppRoutes.voiceTest);
```

---

## What to Expect

### 1. Page Loads
- UI shows "Connecting..." status
- Console logs:
  ```
  🔐 Requesting JWT token for session: xxx
  ✅ Received JWT token (expires in 60 minutes)
  🎙️ Connecting to voice WebSocket: wss://...
  ✅ Connected to voice WebSocket
  🎙️ Sent start_session message
  📨 Received status event: session_started
  ```
- Status changes to "Ready to listen"
- Connection status shows "Connected" (green)

### 2. Click Microphone Button
- Browser requests microphone permission (click "Allow")
- Mic button turns RED with pulsing animation
- Status shows "Listening..."
- Console logs:
  ```
  🎤 Started recording audio
  🎤 Sent audio chunk: 3200 bytes
  🎤 Sent audio chunk: 3200 bytes
  ... (repeats)
  ```

### 3. Speak Clearly
- Interim transcription appears (orange border box):
  ```
  [Listening...]
  "What's the wea"
  ```
- Console logs:
  ```
  📨 Received status event: transcription_interim
  📝 Interim transcription: What's the wea
  ```

### 4. Stop Speaking (or click mic again)
- Final transcription appears (green border box):
  ```
  [✓ Final Transcription]
  "What's the weather in New York?"
  ```
- Console logs:
  ```
  📨 Received status event: transcription_final
  ✅ Final transcription: What's the weather in New York?
  ```

### 5. Agent Processing
- Status shows "Processing..."
- Console logs:
  ```
  📨 Received status event: agent_thinking
  🤔 Agent thinking: Processing your request...
  ```

### 6. Agent Response (TTS)
- Status shows "Speaking..."
- Blue box shows agent's text response
- Audio plays through speakers
- Console logs:
  ```
  📨 Received status event: speaking_started
  🗣️ Speaking started: The weather in New York is 72°F... (4500ms)
  🔊 Received TTS audio: 45632 bytes
  🔊 Playing TTS audio
  ```

### 7. Response Complete
- Status returns to "Ready to listen"
- Console logs:
  ```
  📨 Received status event: speaking_completed
  ✅ Speaking completed
  💾 Audio saved at: voice_audio/session-xxx/interaction-yyy.mp3
  ```
- Can speak again immediately (continuous loop)

---

## Troubleshooting

### Issue: "Cannot connect to WebSocket"
**Check:**
- Is backend running?
- Check console for error codes:
  - `❌ Failed to get voice token` → Backend not running or `/voice/token` endpoint not accessible
  - `🚫 WebSocket closed: code 1008` → Token expired or invalid
  - `🚫 WebSocket closed: code 1011` → Authentication failed

**Solution:**
- Verify backend is running at correct URL
- Check `.env` file has correct `API_BASE_URL` and `WS_BASE_URL`
- Verify backend `JWT_SECRET` is configured

### Issue: "Microphone permission denied"
**Check:**
- Browser settings → Privacy → Microphone
- Chrome: chrome://settings/content/microphone

**Solution:**
- Allow microphone access for localhost
- Refresh page and try again

### Issue: "No audio chunks sent"
**Check:**
- Console shows "Started recording audio" but no "Sent audio chunk" logs

**Solution:**
- Check browser console for recording errors
- Ensure Chrome/Edge browser (best compatibility)
- Check if microphone is working in other apps

### Issue: "No TTS audio plays"
**Check:**
- Console shows "Received TTS audio" but no sound

**Solution:**
- Check browser audio settings
- Verify speakers/headphones are connected
- Check system volume

### Issue: "Transcription empty or incorrect"
**Check:**
- Speak clearly and close to microphone
- Check background noise levels

**Solution:**
- Ensure quiet environment
- Speak at normal pace
- Check backend STT service is working

---

## Debug Console Log Reference

| Emoji | Meaning | Example |
|-------|---------|---------|
| 🔐 | JWT token request | `🔐 Requesting JWT token for session: abc123` |
| ✅ | Success | `✅ Received JWT token (expires in 60 minutes)` |
| 🎙️ | Voice WebSocket | `🎙️ Connecting to voice WebSocket: wss://...` |
| 🎤 | Audio recording | `🎤 Started recording audio` |
| 📨 | Status event | `📨 Received status event: session_started` |
| 📝 | Transcription | `📝 Interim transcription: Hello` |
| 🤔 | Agent thinking | `🤔 Agent thinking: Processing your request...` |
| 🗣️ | Speaking started | `🗣️ Speaking started: The weather is...` |
| 🔊 | Audio playback | `🔊 Received TTS audio: 45632 bytes` |
| 💾 | Audio saved | `💾 Audio saved at: voice_audio/...` |
| ❌ | Error | `❌ Voice WebSocket connection error: ...` |
| 🚫 | Auth error | `🚫 WebSocket closed: Token invalid (code 1008)` |
| ⚠️ | Warning | `⚠️ Token expiring soon (4 minutes)` |
| 🔄 | Reconnecting | `🔄 Reconnecting in 2s (attempt 1/10)...` |

---

## Testing Checklist

- [ ] Backend is running
- [ ] `.env` file configured correctly
- [ ] Flutter app runs without errors
- [ ] Navigate to `/voice-test` page
- [ ] Page connects to backend successfully
- [ ] Microphone permission granted
- [ ] Click mic button, recording starts
- [ ] Audio chunks sent to WebSocket
- [ ] Speak clearly, interim transcription appears
- [ ] Final transcription received
- [ ] Agent processes request
- [ ] TTS audio received and plays
- [ ] Can have multiple back-and-forth exchanges
- [ ] Error handling works (disconnect, reconnect)
- [ ] Token refresh works (test after 55 minutes)

---

## Expected Flow Diagram

```
┌─────────────────────────────────────────────────┐
│         User clicks mic button                  │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│    Flutter requests JWT token (POST /voice/token)│
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend returns token (valid 60 min)           │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Flutter connects WebSocket with token in URL   │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend verifies token, accepts connection     │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Flutter sends start_session message            │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends: session_started                 │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Flutter starts recording PCM audio             │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Flutter streams audio chunks (binary)          │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend transcribes → sends interim results    │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends final transcription              │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends to agent → gets response         │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend generates TTS audio                    │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends: speaking_started                │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends MP3 audio (binary)               │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Flutter plays audio through speakers           │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Backend sends: speaking_completed              │
└──────────────────┬──────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│  Ready for next input (loop back to mic button) │
└─────────────────────────────────────────────────┘
```

---

## Environment Configuration

Make sure `.env` file is configured:

**For local testing:**
```env
API_BASE_URL=http://localhost:8100
WS_BASE_URL=ws://localhost:8100
```

**For production:**
```env
API_BASE_URL=https://api.jarvos.dev
WS_BASE_URL=wss://api.jarvos.dev
```

---

## Next Steps After Testing

Once standalone voice mode is working:

1. **Test continuous conversation** - Multiple back-and-forth exchanges
2. **Test error recovery** - Disconnect backend, reconnect, verify recovery
3. **Test token refresh** - Wait 55 minutes, verify automatic refresh
4. **Integrate into chat** - Add voice button to chat input bar
5. **Deploy to production** - Test on wss://api.jarvos.dev

---

## Questions or Issues?

Check the detailed documentation:
- `VOICE_MODE_README.md` - Full technical documentation
- `VOICE_MODE_IMPLEMENTATION_COMPLETE.md` - Implementation details
- `VOS/docs/FLUTTER_VOICE_JWT_AUTH.md` - Backend JWT auth guide

Or check browser DevTools:
- Console tab - For debug logs
- Network tab - For WebSocket messages (filter: "WS")
- Application tab - For stored tokens/data

---

**Ready to test! 🚀**

Just run `flutter run -d chrome` and navigate to `/voice-test`
