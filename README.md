# SAS Video Player 🎬

> A high-performance, modern video player for **Android (Mobile)** and **Windows (Laptop/Desktop)** with built-in OTA in-app auto-updates.

---

## ✨ Features

- **📱 Mobile (Android)**:
  - Smooth 4K / HD local video playback
  - Hardware accelerated decoding
  - Gesture controls: double tap to seek, pinch to zoom, brightness & volume gestures
  - Background playback & picture-in-picture support
- **💻 Desktop (Windows)**:
  - Windows Media Foundation native acceleration
  - Keyboard shortcuts (Space to toggle play/pause, Arrow keys to seek, F for fullscreen, M for mute)
  - Folder & file picker scanner
- **🚀 Automated CI/CD & OTA Updates**:
  - Automatically builds APK and Windows executables on GitHub Actions
  - Built-in In-App Auto-Updater (`UpdateService`) that automatically prompts users when a new release is available
  - 1-tap download and installation within the app

---

## 📥 Downloads

Download the latest version from [GitHub Releases](https://github.com/sashibitcode/SAS-VIDEO-PLAYER/releases):

- **Android Mobile**: [GS_VIDEO_PLAYER_Android.apk](https://github.com/sashibitcode/SAS-VIDEO-PLAYER/releases/latest/download/GS_VIDEO_PLAYER_Android.apk)
- **Windows PC**: [GS_VIDEO_PLAYER_Windows_x64.zip](https://github.com/sashibitcode/SAS-VIDEO-PLAYER/releases/latest/download/GS_VIDEO_PLAYER_Windows_x64.zip)

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Player Core**: `video_player` / `video_player_win` / `chewie`
- **File & Media Discovery**: `photo_manager` / `file_picker`
- **Auto-Update**: `dio`, `open_filex`, `path_provider`, `http`
- **CI/CD**: GitHub Actions

---

## 🚀 Building Locally

### Prerequisites
- Flutter SDK 3.0+
- Java 17 (for Android)
- Visual Studio with C++ tools (for Windows)

### Commands
```bash
# Get dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on Windows
flutter run -d windows

# Build Release APK
flutter build apk --release
```
