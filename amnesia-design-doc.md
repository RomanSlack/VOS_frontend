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
- Phone, Calendar, Check, Document, Globe
- Chart, Cart, Chat, Bell
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