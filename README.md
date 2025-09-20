# VOS App

A production-ready Flutter application with clean architecture, state management, and CI/CD pipeline.

## Features

- Clean Architecture pattern
- BLoC state management
- Dependency injection with GetIt
- Environment configuration (dev/staging/production)
- Comprehensive testing setup
- CI/CD with GitHub Actions
- Responsive design with Flutter ScreenUtil
- Theme support (Light/Dark)
- Internationalization ready

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/vos_app.git
cd vos_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Set up environment files:
```bash
cp .env.example .env.development
cp .env.example .env.staging
cp .env.example .env.production
```

### Running the App

#### Development
```bash
flutter run --dart-define=ENVIRONMENT=development

flutter run -d chrome --dart-define=ENVIRONMENT=development
```

#### Staging
```bash
flutter run --dart-define=ENVIRONMENT=staging
```

#### Production
```bash
flutter run --release --dart-define=ENVIRONMENT=production
```

## Project Structure

```
lib/
├── app.dart                # Main app widget
├── main.dart              # Entry point
├── core/                  # Core functionality
│   ├── constants/         # App constants
│   ├── di/               # Dependency injection
│   ├── errors/           # Error handling
│   ├── extensions/       # Dart extensions
│   ├── router/           # App routing
│   ├── themes/           # App themes
│   ├── utils/            # Utilities
│   └── widgets/          # Common widgets
├── data/                  # Data layer
│   ├── datasources/      # Remote/Local data sources
│   ├── models/           # Data models
│   └── repositories/     # Repository implementations
├── domain/               # Domain layer
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/        # Business logic
└── presentation/         # Presentation layer
    ├── blocs/           # BLoC state management
    ├── pages/           # App pages/screens
    └── widgets/         # Page-specific widgets
```

## Testing

### Run all tests
```bash
flutter test
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Building

### Android

#### APK
```bash
flutter build apk --release
```

#### App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Code Generation

This project uses code generation for:
- JSON serialization
- Dependency injection
- API client generation

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch for changes:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Linting & Formatting

### Analyze code
```bash
flutter analyze
```

### Format code
```bash
dart format .
```

### Check formatting
```bash
dart format --set-exit-if-changed .
```

## CI/CD

The project includes GitHub Actions workflows for:

- **CI Pipeline**: Runs on push and PR to main/develop branches
  - Code analysis
  - Tests
  - Build for Android, iOS, and Web

- **CD Pipeline**: Runs on version tags (v*)
  - Deploys to Play Store (configure credentials)
  - Deploys to App Store (configure credentials)
  - Deploys to web hosting

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details
