# Reshme Info: Flutter Mobile App (Frontend)

Karnataka Silk Cocoon Real-Time Auction Intelligence Farmer Mobile Application.

---

## Features
- **Real-Time APMC Market Prices**: Live rates from Ramanagara, Sidlaghatta, Kolar, Vijayapura, Kollegala, and other APMCs.
- **7-Day Price Trends**: Interactive high/low weekly charts.
- **1-Tap WhatsApp Share**: Share daily market price slips with farmer groups.
- **Push Bulletins**: Instant price alerts and market reports via Firebase Cloud Messaging.
- **Bilingual Support**: Instant toggle between Kannada (ಕನ್ನಡ) and English.
- **Offline Cache**: Preserves recently viewed prices when offline.
- **Dark & Light Mode**: High-contrast theme optimized for outdoor agricultural readability.

---

## Directory Structure
```
mobile-flutter/
├── lib/
│   ├── core/
│   │   ├── config/            # Supabase & Firebase Initialization
│   │   ├── l10n/              # Kannada & English Translations
│   │   ├── services/          # Analytics, Notifications & Background Sync
│   │   └── theme/             # Royal Sericulture Theme Tokens
│   ├── features/
│   │   ├── home/              # Spotlight Tickers & Tactical Actions
│   │   ├── market/            # Horizontal APMC Chips & Bold Price Cards
│   │   ├── stats/             # Weekly Trend Analytics & High/Low Summary
│   │   ├── info/              # Sericulture Tutorials & Video Lessons
│   │   ├── notifications/     # Dedicated Push Bulletins Screen
│   │   ├── onboarding/        # Language & Primary Market Setup
│   │   └── about/             # Quilonix Partner Profile & Help
│   └── main.dart              # App Entry Point & Routing Shell
├── android/
│   └── app/
│       └── google-services.json # Firebase Configuration
├── test/
│   └── widget_test.dart       # Widget & Smoke Test Suite
└── pubspec.yaml               # Dependencies & Asset Declarations
```

---

## Getting Started

### Prerequisites
- Flutter SDK (3.22.0 or higher)
- Android Studio / VS Code
- Android Device or Emulator

### Installation & Run
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run in debug mode
flutter run

# 3. Run test suite
flutter test
```

---

## Building Release APK / App Bundle

```bash
# Build standalone release APK
flutter build apk --release

# Build Google Play App Bundle (.aab)
flutter build appbundle --release
```
The output file will be generated in `build/app/outputs/flutter-apk/app-release.apk`.
