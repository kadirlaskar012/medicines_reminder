# 💊 MediRemind — KinCare Expressive (Material 3.0)

> **A modern, offline-first Medicine Reminder & Health Companion app built with Flutter.** Designed for rock-solid, on-time alarms across all modern Android versions (Android 10 up to Android 15/16) with warm tactile aesthetics, stock forecasting, and caregiver coordination.

---

## ✨ Key Features

### 🔔 1. Rock-Solid Android 12–15+ Alarm Engine
- **Android 13+ Runtime Permissions**: Supports `POST_NOTIFICATIONS` runtime checks and prompts.
- **Exact Alarms (`SCHEDULE_EXACT_ALARM` & `USE_EXACT_ALARM`)**: Uses idle-wakeup exact scheduling (`AndroidScheduleMode.exactAllowWhileIdle`) so alarms are never delayed by Android Doze mode.
- **Boot Recovery (`RECEIVE_BOOT_COMPLETED`)**: Automatically reschedules all active medicine alarms upon device reboot.
- **Lockscreen Full-Screen Intent (`USE_FULL_SCREEN_INTENT`)**: Wakes the display and shows glowing full-screen alarm cards for critical medications.
- **Battery Optimization Diagnostic**: Built-in system health checker to exempt the app from aggressive manufacturer battery killers (OneUI, MIUI, OxygenOS).

### 🎨 2. KinCare Expressive (Material 3.0) Design System
- **Color Palette**: Curated **Warm Orange (`#FF6B35`)**, **Mint Green (`#10B981`)**, and Soft Sand tones with full Light & Dark mode support.
- **Custom 3D Illustrated Launcher Icon**: Dual-tone glossy capsule with embossed medical cross.
- **Tactile SVG Vector System**: High-detail vector icons for Tablets, Capsules, Syrups, Drops, Inhalers, Injections, Ointments, and Supplements.
- **Micro-Animations**: Smooth card entrances, button shimmers, and pulsating alarm rings powered by `flutter_animate`.

### 📊 3. Dynamic Forecasting & Smart Features
- **Predictive Stock Forecast**: Calculates burn rates based on daily dosing frequency and shows exact countdowns (*"Runs out in X days"* / *"Critical: <3 days"*).
- **One-Tap Quick Refill**: Instant `+10`, `+20`, `+30` pill inventory refill buttons in the Cabinet screen.
- **Tactile Haptic Feedback**: Sensory vibrations on taking, snoozing, or skipping medications (`HapticFeedback`).
- **1-Page Doctor Consultation PDF**: Generates offline on-device printable summary reports with adherence gauge, prescription table, and doctor sign-off block.
- **Caregiver WhatsApp & SMS SOS Alerts**: Instantly dispatches alerts for overdue doses via WhatsApp and SMS intents.
- **Multi-Member Care Circle**: Switch seamlessly between schedules for *Myself*, *Mom*, *Dad*, or *Child*.

---

## 📱 Mobile APK Download

A ready-to-test optimized release APK is included directly in the root directory:
- **`MediRemind-arm64-recommended.apk`** (~19.88 MB): Highly optimized 64-bit release build for modern Android phones.

---

## 🛠 Tech Stack & Architecture

- **Framework**: Flutter 3.x / Dart SDK 3.x
- **State Management**: `provider` (Reactive, offline-first)
- **Local Database**: `sqflite` (SQLite storage for profiles, medicines, schedules, and intake logs)
- **Notifications**: `flutter_local_notifications` + `timezone`
- **Charts & Reporting**: `fl_chart`, `pdf`, `printing`
- **Vectors & Fonts**: `flutter_svg`, `google_fonts` (*Outfit*)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.19+)
- Android SDK (API 34/35+)
- Java 17+

### Installation & Run
```bash
# Clone the repository
git clone https://github.com/kadirlaskar012/medicines_reminder.git
cd medicines_reminder

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit tests
flutter test

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release --split-per-abi
```

---

## 📄 License
This project is licensed under the MIT License.
