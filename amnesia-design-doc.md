# VOS Design System Documentation

## 🎯 Project Overview
**VOS (Virtual Operating System)** - A Flutter-based virtual operating system application with a modern, sleek AI-powered interface. The app features a dark theme with subtle bevels, elegant shadows, and a cohesive design language inspired by modern OS interfaces.

---

## 🎨 Color Palette

### Primary Colors
- **Background**: `#212121` - Main app background (dark grey)
- **Surface Primary**: `#303030` - Primary surface for components (app rail, input bar)
- **Surface Secondary**: `#424242` - Secondary surface for icon circles
- **Text Primary**: `#EDEDED` - Primary text and icons (off-white)
- **Text Secondary**: `#757575` - Secondary text (placeholder text)
- **Border Subtle**: `white @ 10% opacity` - Subtle borders for depth
- **Border Dark**: `#212121` - Special border for user icon

### Color Usage Rules
1. **Never use pure white** - Always use `#EDEDED` for off-white elements
2. **Components use `#303030`** - All major UI surfaces (rails, bars)
3. **Icons sit in `#424242` circles** - Consistent icon background
4. **Text is always `#EDEDED` or `#757575`** - No other text colors

---

## 🏗️ Component Architecture

### Core Components Location
```
lib/presentation/widgets/
├── app_rail.dart       # Left navigation rail
├── input_bar.dart      # Bottom input bar
└── circle_icon.dart    # Reusable icon component
```

---

## 🎭 Visual Design Patterns

### Bevel & Shadow System
All major components follow this consistent styling:

```dart
// Standard component decoration
BoxDecoration(
  color: const Color(0xFF303030),
  borderRadius: BorderRadius.circular(24),  // Rounded corners
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      offset: const Offset(4, 0),  // Horizontal for rail, vertical for bars
      blurRadius: 12,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      offset: const Offset(2, 0),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ],
  border: Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  ),
)
```

### Key Visual Rules:
- **Rounded corners**: 24px for major components, 30px for pills
- **Multiple shadows**: Always use 2 shadows for depth
- **Subtle borders**: White @ 10% opacity, 1px width
- **No gradients**: Pure solid colors only

---

## 🔘 Icon System

### CircleIcon Component
Reusable icon component with consistent styling:

```dart
CircleIcon(
  icon: Icons.phone_outlined,  // Always use outlined versions
  size: 48,                     // 48px for rail, 40px for input bar
  useFontAwesome: false,        // Material Icons work better
  backgroundColor: Color(0xFF424242),  // Optional override
  borderColor: Color(0xFF212121),      // Optional border
  onPressed: () {},
)
```

### Icon Guidelines:
1. **Always use outlined/line versions** - Never filled icons
2. **Icon color is `#EDEDED`** - Consistent off-white
3. **Circle background is `#424242`** - Except special cases
4. **Hover animation**: Scale to 110% with enhanced shadow
5. **Icon sizing**: 50% of circle diameter

### Icon Sizes:
- **App Rail Icons**: 48px circles
- **Input Bar Icons**: 40px circles
- **Icon inside circle**: 50% of circle size

---

## 📱 Component Specifications

### App Rail (Left Navigation)
- **Width**: 80px
- **Margin**: 16px all sides
- **Border Radius**: 24px
- **Color**: `#303030`
- **Icon Spacing**: 12px vertical
- **Special Spacing**: 48px before plus icon (4x normal)
- **User Icon**: Bottom with `#212121` border, `#303030` background

### Input Bar (Bottom)
- **Height**: 60px
- **Width**: 600px
- **Bottom Margin**: 24px
- **Border Radius**: 30px (pill shape)
- **Color**: `#303030`
- **Padding**: 16px horizontal
- **Icons**: Right-aligned with 8px spacing

---

## ⚡ Interaction Patterns

### Hover Effects
All interactive elements have hover states:
1. **Scale animation**: 110% on hover
2. **Shadow enhancement**: Increased opacity and blur
3. **Duration**: 150ms with ease-in-out curve
4. **MouseRegion**: Desktop hover support

### Animation Example:
```dart
AnimationController(
  duration: const Duration(milliseconds: 150),
  vsync: this,
);
// Scale from 1.0 to 1.1 with CurvedAnimation
```

---

## 🏛️ Architecture Patterns

### State Management
- **BLoC Pattern** for state management (prepared, not fully implemented)
- **GetIt** for dependency injection (setup ready)

### Folder Structure:
```
lib/
├── presentation/
│   ├── pages/        # Screen widgets
│   └── widgets/      # Reusable components
├── core/
│   ├── themes/       # Theme definitions
│   └── router/       # Navigation
```

### Widget Patterns:
1. **Stateless by default** - Use StatefulWidget only for animations
2. **Const constructors** - Always use const where possible
3. **Separate concerns** - Components in individual files
4. **Production ready** - Error handling, proper disposal

---

## 🚀 Quick Start Code Examples

### Creating a New Beveled Component:
```dart
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF303030),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: 1,
      ),
    ],
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
  ),
  child: // Your content
)
```

### Adding a New Icon:
```dart
CircleIcon(
  icon: Icons.your_icon_outlined,
  size: 48,
  useFontAwesome: false,
  onPressed: () {
    // Handle tap
  },
)
```

---

## 📋 Current UI Elements

### Implemented Components:
1. **AppRail** - Left navigation with 11 icons
2. **InputBar** - Bottom input with mic and waveform icons
3. **CircleIcon** - Reusable icon component with hover

### Icons in App Rail (top to bottom):
- Phone, Calendar, Tasks, Notes, Browser
- Analytics, Shop, Chat, Weather (Cloud)
- Plus (with extra spacing)
- User (at bottom with special styling)

### Icons in Input Bar:
- Microphone (STT)
- Waveform (audio visualization)

---

## 🎯 Design Philosophy

### Core Principles:
1. **Dark & Modern** - Embracing dark UI with subtle depth
2. **Consistent Spacing** - 12px base unit for spacing
3. **Subtle Animations** - Smooth, not distracting
4. **Accessible Contrast** - Off-white on dark for readability
5. **Production Quality** - Clean code, proper patterns

### Visual Hierarchy:
- **Primary Surface** (`#303030`) - Major containers
- **Secondary Surface** (`#424242`) - Icon backgrounds
- **Background** (`#212121`) - Base canvas
- **Content** (`#EDEDED`) - Text and icons

---

## 🔧 Development Tips

### Hot Reload Issues:
- If icons don't load, use Material Icons instead of FontAwesome
- Always specify `useFontAwesome: false` for Material Icons

### Color References:
```dart
// Quick color constants to copy
const darkBackground = Color(0xFF212121);
const surfacePrimary = Color(0xFF303030);
const surfaceSecondary = Color(0xFF424242);
const textPrimary = Color(0xFFEDEDED);
const textSecondary = Color(0xFF757575);
```

### Testing Command:
```bash
flutter run -d chrome --dart-define=ENVIRONMENT=development
```

---

## 📝 Notes for Future Development

This design system creates a cohesive, modern virtual OS interface. The dark theme with subtle bevels gives depth without being heavy. The consistent use of circles for icons creates a unified interaction language. The color palette is minimal but effective, creating clear hierarchy without complexity.

Remember: **Consistency is key** - Always follow these patterns for new components.

## 🧪 Testing Protocol

**IMPORTANT**: The user handles all app testing and execution. When implementing components:

- ✅ **You should**: Run `flutter analyze`, validate syntax, check imports
- ❌ **User will**: Test the app, run scripts, verify functionality

After creating/fixing components, inform the user you're ready for their testing. Do not attempt to run the full application yourself.

## 📄 Current Components

### Workspace Component
- **Location**: `lib/presentation/widgets/workspace.dart`
- **Purpose**: Grid background area to the right of AppRail
- **Features**: `#2F2F2F` grid with edge fade effects, 30 grids wide, responsive height

### VosModal Component
- **Location**: `lib/presentation/widgets/vos_modal.dart`
- **Purpose**: Reusable modal windows for apps within workspace
- **Features**:
  - Draggable title bar with app title
  - Window controls: minimize, fullscreen, close, app icon
  - Resizable from bottom-right corner with visual handle
  - Three states: normal, minimized, fullscreen
  - VOS design system styling with bevels and shadows
  - Workspace boundary constraints
  - Production-grade gesture handling

### Modal Management System
- **Core**: `lib/core/modal_manager.dart` - VosModalManager class
- **Features**:
  - **4 Modal Limit**: Maximum 4 apps open simultaneously
  - **App Integration**: 9 predefined apps (Phone, Calendar, Tasks, Notes, Browser, Analytics, Shop, Chat, Weather)
  - **Visual States**: AppIcon component shows green dot (open), orange dot with pulse (minimized)
  - **Smart Positioning**: Auto-cascading modal positions
  - **Limit Notification**: Elegant warning when trying to open 5th modal
  - **State Persistence**: Maintains open/minimized states across interactions
- **UI Components**:
  - `AppIcon`: Enhanced rail icons with state indicators
  - `ModalLimitNotification`: Animated warning with app preview

---

## 💬 AI Assistant & Chat System

### Chat Application
- **Location**: `lib/presentation/widgets/chat_app.dart`
- **Purpose**: Full ChatGPT-style AI assistant integration
- **Features**:
  - **Real OpenAI API Integration**: Live chat completions via FastAPI backend
  - **Message Bubbles**: User messages (right, compact) vs AI messages (left, full-width)
  - **Auto-scroll**: Smooth scrolling to new messages
  - **Thinking Animation**: 3-dot animated indicator during AI responses
  - **Message Count**: Header shows total conversation messages
  - **No Input Bar**: Uses main VOS input bar exclusively
  - **Error Handling**: Production-grade connection and API error handling

### Chat Backend Integration
- **API Service**: `lib/core/services/chat_service.dart`
- **HTTP Client**: Dio with Retrofit for type-safe API calls
- **Models**: `lib/core/models/chat_models.dart` with JSON serialization
- **Endpoint**: FastAPI server at `http://localhost:5555/chat/completions`
- **Real API**: No mock data - connects to OpenAI via FastAPI backend

### Chat Manager
- **State Management**: `lib/core/chat_manager.dart` - ChangeNotifier pattern
- **Message History**: Persistent conversation within session
- **Integration**: Auto-opens when typing in main input bar
- **Duplicate Prevention**: Smart message deduplication system

---

## 🌤️ Weather Application

### Weather App
- **Location**: `lib/presentation/widgets/weather_app.dart`
- **Purpose**: Real-time weather display for Rochester, NY
- **Features**:
  - **Live Weather Data**: Real API connection to weather service
  - **Current Conditions**: Large temperature display with weather icon
  - **Location Display**: Shows "Rochester, NY" from API
  - **Weather Details**: Humidity and wind speed in elegant cards
  - **Smart Icons**: Dynamic weather icons based on conditions (cloud, sun, rain, etc.)
  - **Status Indicators**: Green/yellow/red dot shows connection status
  - **Auto-refresh**: Manual refresh button with "last updated" timestamp
  - **Error Handling**: Elegant error states with retry functionality
  - **No Mock Data**: Production-ready with real weather API

### Weather Backend Integration
- **API Service**: `lib/core/services/weather_service.dart`
- **HTTP Client**: Dio with Retrofit for type-safe API calls
- **Models**: `lib/core/models/weather_models.dart` with JSON serialization
- **Endpoint**: FastAPI server at `http://localhost:5555/weather/rochester`
- **JSON Response**: `{"location":"Rochester, NY","temperature":72.5,"description":"Partly cloudy","humidity":65,"wind_speed":8.2,"feels_like":75.1}`

---

## 📝 Notes Application

### Notes App
- **Location**: `lib/presentation/widgets/notes_app.dart`
- **Purpose**: Full-featured text editor/notepad
- **Features**:
  - **Multi-line Text Editor**: Expandable text input with monospace font
  - **Header Actions**: Select All, Copy All, Clear All with confirmation
  - **Status Bar**: Live character/line count and editing status
  - **Clean Styling**: No blue selection colors, matches VOS input bar design
  - **Session-based**: No persistence - clears on app close/refresh
  - **Button States**: Actions disabled when no content

---

## 📅 Calendar Application

### Calendar App
- **Location**: `lib/presentation/widgets/calendar_app.dart`
- **Purpose**: Full-featured calendar with month navigation
- **Features**:
  - **Month Navigation**: Previous/next month with today button
  - **Date Selection**: Click any date to select
  - **Visual States**: Today highlighting, selected date, past dates styling
  - **Responsive Grid**: Dynamic week calculation with proper date math
  - **Action Buttons**: Placeholder "Add Event" and "View Day" functionality
  - **Overflow-free**: Optimized layout for modal constraints

---

## 🏗️ Backend Architecture

### FastAPI Server
- **Location**: `/home/roman/simple_chat_tester/startup.py`
- **Purpose**: Backend API server for VOS apps
- **Endpoints**:
  - `/chat/completions` - OpenAI chat completions proxy
  - `/weather/rochester` - Rochester weather data
  - `/health` - Health check endpoint
- **Features**:
  - **CORS Enabled**: Supports Flutter web development
  - **OpenAI Integration**: Real API key usage for chat
  - **Weather API**: OpenWeatherMap integration with fallback
  - **Production Ready**: Proper error handling and logging

### Dependency Injection
- **Service**: `lib/core/di/injection.dart`
- **Pattern**: GetIt singleton registration
- **Services**: ChatService, WeatherService auto-registered
- **Lifecycle**: Initialized before app startup

---

## 🔄 API Integration Patterns

### HTTP Architecture
- **Client**: Dio with debug logging in development
- **Code Generation**: Retrofit + JSON serialization via build_runner
- **Error Handling**: Specific HTTP status code handling
- **Type Safety**: Full DTO models with fromJson/toJson

### Service Pattern
```dart
// Example service structure
class WeatherService {
  late final WeatherApi _weatherApi;
  late final Dio _dio;

  Future<WeatherData> getCurrentWeather() async {
    // Real API call with proper error handling
  }
}
```

### Modal Integration
- **Special Apps**: Chat, Calendar, Notes, Weather get special handling
- **Service Injection**: Apps receive services via dependency injection
- **Custom Sizing**: Each app has optimized modal dimensions
- **State Management**: Apps maintain state within modal lifecycle