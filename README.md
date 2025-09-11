# StudyMate 📚

Collaborative Study Organizer App

A **Flutter-based collaborative study organizer** designed for college students to manage tasks, plan study routines, and share notes efficiently.

---

## 🚀 Features

### 📝 Task Management

* Create, edit, and delete tasks with deadlines
* Priority-based task organization (Low, Medium, High)
* Subject and category categorization
* Smart notifications and reminders
* Task completion tracking
* Due date and reminder scheduling

### 📓 Note Taking

* Rich note creation and editing
* Subject and category organization
* Tag-based note organization
* Favorites system for important notes
* Word count and reading time estimation
* Note duplication functionality

### 🔔 Smart Notifications

* Task reminder notifications
* Customizable notification settings
* Exact alarm scheduling (Android 12+ compatible)
* Offline notification support
* Permission-aware notification handling

### 🗄️ Data Management

* Local storage with Hive database
* Firebase integration for cloud sync
* Offline-first architecture
* Data backup and restore capabilities

### 🎨 User Interface

* Modern Material Design UI
* Responsive design for all screen sizes
* Dark/Light theme support
* Intuitive navigation
* Tab-based organization

---

## 🛠️ Tech Stack

### Frontend

* **Flutter 3.35.3+** – Cross-platform mobile framework
* **Dart 3.9.2+** – Programming language

### Database & Storage

* Hive – Local NoSQL database for offline storage
* Firebase Firestore – Cloud database for sync
* Shared Preferences – App settings storage

### State Management

* StatefulWidget – Built-in Flutter state management
* Provider Pattern – Service-based architecture

### Authentication & Backend

* Firebase Auth – User authentication
* Firebase Cloud Firestore – Cloud database
* Firebase Storage – File storage (future feature)

### Notifications

* Flutter Local Notifications – Local push notifications
* Firebase Cloud Messaging – Remote notifications (future feature)

### Additional Packages

* UUID – Unique ID generation
* Intl – Internationalization
* Image Picker – Image selection
* Timezone – Timezone handling
* Path Provider – File system access

---

## 📱 Screenshots

*(Screenshots will be added soon)*

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK 3.35.3+
* Dart SDK 3.9.2+
* Android Studio or VS Code
* Git

### Installation

Clone the repository:

```bash
git clone https://github.com/vrundpatel111/study_mate.git
cd study_mate
```

Install dependencies:

```bash
flutter pub get
```

### Firebase Setup (Optional – for cloud features)

1. Create a Firebase project in [Firebase Console](https://console.firebase.google.com/)
2. Download `google-services.json` (Android)
3. Download `GoogleService-Info.plist` (iOS)
4. Place them in respective platform directories
5. Enable Firestore Database and Authentication

### Run the App

```bash
flutter run
```

### Building for Production

**Android**

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS**

```bash
flutter build ios --release
```

---

## 🏗️ Project Structure

```
lib/
├── models/           # Data models
│   ├── task.dart
│   ├── note.dart
│   └── *.g.dart     # Generated Hive adapters
├── services/         # Business logic services
│   ├── task_service.dart
│   ├── note_service.dart
│   ├── notification_service.dart
│   ├── auth_service.dart
│   └── firebase_service.dart
├── screens/          # UI screens
│   ├── tasks/
│   ├── notes/
│   ├── auth/
│   └── home/
├── main.dart         # App entry point
└── firebase_options.dart
```

---

## 🔧 Configuration

### Android Permissions

* `WAKE_LOCK` – Keep device awake for notifications
* `RECEIVE_BOOT_COMPLETED` – Start services after reboot
* `VIBRATE` – Notification vibration
* `USE_EXACT_ALARM` – Precise alarm scheduling
* `SCHEDULE_EXACT_ALARM` – Schedule exact alarms
* `POST_NOTIFICATIONS` – Show notifications
* `USE_FULL_SCREEN_INTENT` – Full screen notifications

### Firebase Configuration

1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Configure security rules (see `firestore.rules`)

---

## 📋 Features Roadmap

✅ **Completed**

* Task management with priorities
* Note creation and editing
* Local data storage
* Notification system
* Firebase integration
* Responsive UI design
* Offline functionality

🔄 **In Progress**

* Study groups and collaboration
* File attachments for notes
* Study statistics and analytics

📅 **Planned**

* Calendar integration
* Study session timer
* Note sharing
* Collaborative note editing
* Study goal tracking
* Progress analytics
* Export functionality

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🐛 Issues & Bug Reports

If you encounter bugs or have feature requests, please open an issue in the [GitHub Issues](https://github.com/vrundpatel111/study_mate/issues) section.

---

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Vrund Patel**
GitHub: [@vrundpatel111](https://github.com/vrundpatel111)

---

## 🙏 Acknowledgments

* Flutter team for the amazing framework
* Firebase for backend services
* Material Design for UI guidelines
* All contributors and testers

---

Now this README will look clean and professional on GitHub.

Do you want me to also **add shields/badges** (like Flutter version, License, Firebase, etc.) at the top? That would make it look even more polished.
