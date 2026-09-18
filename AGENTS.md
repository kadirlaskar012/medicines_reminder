# MediRemind Development Guidelines & Agent Memory

## 1. Testing & Deployment Protocol (User Instruction)
- **Do NOT perform repetitive manual/interactive UI testing yourself**: Do not spend time tapping through the app screens with adb shell input or repeatedly capturing full UI verification screenshots unless specifically instructed by the user.
- **Build & Install Directly**:
  - After making code changes and verifying with `flutter analyze` and `flutter test`, build the APK and install it directly to the connected Android device:
    ```bash
    flutter build apk --release
    adb install -r build/app/outputs/flutter-apk/app-release.apk
    ```
  - Notify the user once the app is installed. The user will personally test the app on their phone and instruct if any further changes or updates are needed.

## 2. Design & Aesthetic Standards
- **Premium & Colorful UI**:
  - Keep the app vibrant, modern, and luxurious.
  - Never revert to plain, basic, unstyled, or "simple HTML" appearances.
  - Use squircle icon containers with gradient backgrounds, soft shadows, elevated cards, and clear typography.
- **Bottom Navigation Colors**:
  - Each navigation item must preserve its unique, distinct color theme:
    - **Today**: Royal Indigo / Electric Blue (`#4F46E5`)
    - **Medicines**: Vibrant Emerald Teal / Mint (`#0D9488`)
    - **Add Medicine (`+` FAB)**: Multi-color radiant gradient (`#0D9488` → `#06B6D4` → `#3B82F6`)
    - **Reports**: Royal Violet / Radiant Purple (`#7C3AED`)
    - **Settings**: Sunset Coral / Radiant Amber (`#EA580C`)

## 3. Versioning & Configuration
- Preserve `version: 1.0.0+1` in `pubspec.yaml` unless the user explicitly requests a version bump.
- Always commit and push changes to `origin/main` when requested.
