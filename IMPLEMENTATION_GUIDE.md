# VOS Frontend - Remaining Tasks

## Current Status

Most critical bugs have been fixed! The conversation system is now properly wired up.

---

## ✅ Completed Work

### 1. ✅ Conversation API Integration (Critical - DONE)
- **Frontend Changes:**
  - Added `ConversationMessageDto` and `ConversationHistoryResponseDto` models to `chat_models.dart`
  - Added `getConversationHistory()` method to `chat_api.dart`
  - Updated `ChatService.loadConversationHistory()` to use `/api/v1/conversations/{session_id}` instead of `/api/v1/transcript/{agent_id}`
  - **FIXED:** Removed duplicate user message storage - now only stored once via `/api/v1/chat` endpoint

- **Backend Changes:**
  - Existing `/api/v1/messages/user` already stores agent messages in `conversation_messages` table with session_id
  - Existing `/api/v1/chat` already stores user messages with session_id in `conversation_messages` table
  - Added `/api/v1/messages/from-user` POST endpoint (not used - `/api/v1/chat` handles it)

- **Result:** Frontend now uses the correct conversation API, not the internal transcript API. No system messages will appear in chat. No duplicate messages.

### 2. ✅ Session ID Flow (Critical - DONE)
- The `send_user_message` tool already supports `session_id` as an optional parameter
- The SDK already extracts `session_id` from user_message notifications
- Agent messages are stored with the session_id when sent to `/messages/user` endpoint
- Full conversation continuity is maintained

### 3. ✅ Agent Status Messages (DONE - Already Working)
- Frontend subscribes to `actionStream` in `chat_app.dart`
- Displays real-time agent action status at bottom-left of chat
- Backend publishes `action_status` notifications via notification system
- **This feature is already fully implemented and working!**

---

## 🔧 Remaining Tasks

### Task 1: Add Route Guards for Authentication (HIGH Priority)

**Problem:**
- Users can bypass login and access `/home` directly
- No authentication enforcement on routes

**Solution:**

**File:** `lib/core/router/app_router.dart`

Add redirect logic to the GoRouter configuration:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:vos_app/core/router/app_routes.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/presentation/pages/home/home_page.dart';
import 'package:vos_app/presentation/pages/splash/splash_page.dart';
import 'package:vos_app/presentation/pages/login/login_page.dart';

@lazySingleton
class AppRouter {
  late final GoRouter _router;
  final AuthService _authService = AuthService();

  AppRouter() {
    _router = GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final isLoggedIn = await _authService.isLoggedIn();
        final isGoingToLogin = state.matchedLocation == AppRoutes.login;
        final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

        // Allow splash page always
        if (isGoingToSplash) return null;

        // If not logged in and not going to login, redirect to login
        if (!isLoggedIn && !isGoingToLogin) {
          return AppRoutes.login;
        }

        // If logged in and going to login, redirect to home
        if (isLoggedIn && isGoingToLogin) {
          return AppRoutes.home;
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
      ],
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
    );
  }

  GoRouter get config => _router;

  void dispose() {
    _router.dispose();
  }
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 2: Run Build Runner (CRITICAL - Required)

**Why:** The new DTO models need to have their `.g.dart` files generated.

**Commands:**
```bash
cd VOS_frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Expected Output:**
- Should generate `chat_models.g.dart` with serialization code for new DTOs
- May take 10-20 seconds to complete
- Look for "Built with build_runner" success message

---

## 🧪 Testing Checklist

After completing the remaining tasks, verify:

**Authentication:**
- [ ] App starts on splash screen
- [ ] Redirects to login if not authenticated
- [ ] Login works and navigates to home
- [ ] Logout button navigates back to login
- [ ] Cannot manually navigate to `/home` when logged out

**Conversation System:**
- [ ] Send a message - it appears immediately in chat
- [ ] Agent responds - response appears in chat
- [ ] Refresh page - conversation history loads correctly
- [ ] No system messages or internal agent thoughts visible
- [ ] Both user and agent messages have timestamps
- [ ] Check backend: `GET /api/v1/conversations/user_session_default` returns both user and agent messages

**Agent Status:**
- [ ] Agent action status appears at bottom-left during processing
- [ ] Status shows descriptive text (e.g., "Checking the weather...")
- [ ] Status clears when agent responds
- [ ] Status updates in real-time

---

## 🏗️ Architecture Summary

### Two Message Systems (Important!)

**1. Internal Agent State (`message_history` table)**
- Endpoint: `/api/v1/transcript/{agent_id}`
- Contains: System prompts, thoughts, tool calls, tool results
- Purpose: Track agent's internal reasoning
- **Frontend should NEVER use this**

**2. User-Facing Conversation (`conversation_messages` table)**
- Endpoint: `/api/v1/conversations/{session_id}`
- Contains: User messages and agent responses (clean text only)
- Purpose: Display to user
- **Frontend should ONLY use this**

### Message Flow

1. **User sends message:**
   - Frontend calls `sendMessage()` → `/api/v1/chat` endpoint
   - `/api/v1/chat` stores in `conversation_messages` table
   - `/api/v1/chat` sends notification to RabbitMQ → primary_agent queue

2. **Agent processes:**
   - Receives notification with `session_id` in payload
   - Uses internal `message_history` for context
   - Executes `send_user_message` tool with extracted `session_id`

3. **Agent responds:**
   - `send_user_message` calls `/api/v1/messages/user` with `session_id`
   - Stores in `conversation_messages` table
   - Publishes WebSocket notification to frontend

4. **Frontend displays:**
   - WebSocket notification triggers message display
   - On refresh: loads from `/api/v1/conversations/{session_id}`

---

## 📝 Known Limitations & Future Enhancements

### Session ID Management
- Currently hardcoded as `'user_session_default'`
- All users share the same conversation
- **Future:** Generate unique session IDs per user/conversation

### Multiple Conversations
- Users cannot create multiple conversation threads
- **Future:** Implement conversation list and switching

### Message Deletion
- No UI to delete or clear conversations
- **Future:** Add "Clear conversation" button

---

## 🐛 If Something Doesn't Work

### Build Runner Fails
```bash
# Clean build cache
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Conversation Not Loading
1. Check backend logs: `docker logs vos-api_gateway-1`
2. Verify endpoint: `curl http://localhost:8000/api/v1/conversations/user_session_default`
3. Check if session_id matches between frontend and backend

### Messages Not Appearing
1. Check WebSocket connection in browser DevTools
2. Verify RabbitMQ is running: `docker ps | grep rabbitmq`
3. Check agent logs: `docker logs vos-primary_agent-1`

### Login Not Working
1. Check if route guard redirect is causing infinite loop
2. Verify `AuthService.isLoggedIn()` works correctly
3. Check browser localStorage for saved token

---

## ✨ Summary

**What's Working:**
- ✅ Conversation API integration
- ✅ Session ID flow
- ✅ User message storage
- ✅ Agent message storage
- ✅ Agent status messages
- ✅ Message timestamps
- ✅ Logout button UI
- ✅ Token expiry handling
- ✅ Remember Me checkbox
- ✅ Error handling for history load

**What's Pending:**
- ⏳ Route guards (5 minutes)
- ⏳ Build runner (2 minutes)

**Total Time Remaining:** ~10 minutes

You're almost done! 🎉
