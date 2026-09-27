# Required Tools

## Local development

- Git and a remote repository for source history and backup.
- Flutter SDK with the bundled Dart SDK.
- Codex CLI, IDE extension, or desktop app opened at the repository root.
- VS Code or another Flutter-compatible editor.
- Android Studio, Android SDK, emulator, and `adb`.
- A JDK version compatible with the Flutter/Android toolchain.
- A physical Android tablet for final validation.

Do not guess versions. During Milestone 0, run `flutter doctor -v`, verify the Android toolchain, and record the working versions in the repository README.

## Expected packages

The exact package versions must be selected after compatibility checks. The expected roles are:

- SQLite access and transactions: a maintained Flutter SQLite package, initially evaluate `sqflite`.
- File paths: a maintained path utility package if required by the SQLite adapter.
- UUIDs: a small UUID package if application-generated IDs are needed.
- Date/time formatting: the Dart/Flutter `intl` package if built-in formatting is insufficient.
- Android file selection: a maintained file-picker or Storage Access Framework package.

Avoid adding packages for state management, networking, analytics, authentication, or cloud services in the MVP.

## Development commands

```bash
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter run
flutter build apk --debug
```

## Artifacts the project should produce

- Versioned Flutter source code.
- `AGENTS.md` with the actual commands and conventions.
- Numbered SQL migrations.
- Unit, repository, widget, and critical integration tests.
- Debug APKs during development and a release candidate APK.
- A sanitized example backup with no real customer data.
- A manual tablet test checklist.
- Release notes and an upgrade procedure.

## Not needed for the MVP

- Node.js or npm.
- React, Vite, MUI, or Capacitor.
- Docker.
- AWS, Firebase, or another cloud service.
- Express or a separate backend.
- Socket.IO or WebSockets.
- PostgreSQL or MySQL.
- CI/CD for mobile deployment on the first day.
