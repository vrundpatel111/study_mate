# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**StudyMate** is a collaborative study organizer Flutter app for college students to manage tasks, plan study routines, and share notes. It features offline-first architecture with Firebase sync, local storage via Hive, and notification support.

## Common Development Commands

### Essential Flutter Commands
```bash
# Run the app in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for release (Android)
flutter build apk --release

# Build for release (Windows)
flutter build windows --release

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

### Code Generation Commands
```bash
# Generate Hive type adapters (required after model changes)
flutter packages pub run build_runner build

# Watch for changes and regenerate automatically
flutter packages pub run build_runner watch

# Clean generated files and regenerate
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests (if available)
flutter drive --target=test_driver/app.dart
```

## Architecture Overview

### Project Structure
The app follows a layered architecture pattern:

```
lib/
├── main.dart              # App entry point with Firebase/Hive initialization
├── main_complex.dart      # Full-featured version (Firebase + offline)
├── main_simple.dart       # Simplified version (local-only)
├── models/               # Hive data models with type adapters
│   ├── task.dart         # Task model with priority, due dates, tags
│   ├── note.dart         # Note model with search, categories, favorites
│   └── user.dart         # User model for Firebase auth
├── services/             # Business logic and data management
│   ├── auth_service.dart     # Firebase authentication
│   ├── task_service.dart     # Task CRUD with Hive storage
│   ├── note_service.dart     # Note CRUD with Hive storage
│   ├── user_service.dart     # User profile management
│   └── notification_service.dart # Local notifications
└── screens/              # UI screens organized by feature
    ├── auth/            # Login, register, forgot password
    ├── home/            # Main navigation screen
    ├── tasks/           # Task management screens
    ├── notes/           # Note management screens
    ├── calendar/        # Calendar view
    └── profile/         # User profile
```

### Data Layer Architecture

**Offline-First Design**: The app prioritizes local storage (Hive) for immediate responsiveness, with Firebase providing cloud sync and authentication.

**Hive Models**: 
- All data models extend `HiveObject` for local persistence
- Use `@HiveType` and `@HiveField` annotations for code generation
- Models include computed properties and utility methods

**Service Layer**:
- Each service manages a specific domain (tasks, notes, auth)
- Services handle both local Hive operations and Firebase sync
- Notification scheduling integrated with task reminders

### Key Components

**Task Management**:
- Priority levels (low/medium/high) with color coding
- Due date tracking with overdue detection
- Tag-based organization and filtering
- Reminder notifications with scheduling

**Note System**:
- Rich text content with image support
- Subject-based categorization
- Favorite marking and search functionality
- Word count and reading time estimates





**Authentication Flow**:
- Firebase Auth with email/password
- Automatic user document creation in Firestore
- Profile management with display name updates
- Password reset functionality

## Development Guidelines

### Multiple Entry Points
- `main.dart`: Full app with Firebase and all features
- `main_complex.dart`: Identical to main.dart (backup/reference)
- `main_simple.dart`: Simplified version without Firebase (for quick testing)

### Code Generation Workflow
After modifying Hive models in `lib/models/`:
1. Update the `@HiveField` annotations if needed
2. Run `flutter packages pub run build_runner build`
3. Register new adapters in `main.dart` if adding new models

### Firebase Configuration
- Project uses `studymate-42b3e` Firebase project
- Firebase options auto-generated in `firebase_options.dart`
- Multi-platform support (Android, iOS, Web, Windows, macOS)

### State Management Pattern
The app uses StatefulWidget with local state management:
- Services handle data persistence and business logic
- Widgets call service methods directly
- `StreamBuilder` used for Firebase auth state management

### Testing Approach
- Widget tests in `test/widget_test.dart`
- Test both online and offline functionality
- Mock Firebase services for unit testing

## Common Patterns

### Adding New Data Models
1. Create model class extending `HiveObject` in `lib/models/`
2. Add `@HiveType` and `@HiveField` annotations
3. Run code generation: `flutter packages pub run build_runner build`
4. Register adapter in `main.dart`: `Hive.registerAdapter(NewModelAdapter())`
5. Open corresponding Hive box: `await Hive.openBox<NewModel>('boxName')`

### Service Implementation Pattern
Services follow consistent patterns:
- Constructor initializes Hive box reference
- CRUD methods (get, add, update, delete)
- Specialized query methods (search, filter, sort)
- Statistics and utility methods
- UUID generation for unique IDs

### Notification Integration
Task reminders use the local notification system:
- Schedule notifications via `NotificationService`
- Use task ID hash as notification ID
- Cancel notifications when tasks complete
- Support timezone-aware scheduling
