# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter tournament-style ("World Cup") game application called "내가 만든 월드컵" (My Custom World Cup). Users can create custom tournaments with their own images, play through elimination rounds, and share results via KakaoTalk.

**Key Technologies:**
- Flutter/Dart
- SQLite for local data storage  
- ImgBB for image hosting
- Provider for state management
- KakaoTalk SDK for sharing
- Google Mobile Ads integration

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for release
flutter build apk --release
flutter build appbundle --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Generate launcher icons
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## Architecture Overview

### Core Models
- `WorldCupModel` - Represents a tournament with title, description, max rounds
- `WorldCupItemModel` - Represents individual items/images in a tournament

### Key Components
- **Database Layer**: `lib/db/sqlite.dart` - SQLite database with singleton pattern
- **Data Access**: `lib/dto/worldcup_dao.dart` - Database operations for tournaments and items
- **State Management**: `lib/provider/worldcup_select_provider.dart` - Provider for game selections
- **API Integration**: 
  - `lib/api/imgbb_upload.dart` - Image uploading to ImgBB
  - `lib/api/kakaotalk_feed.dart` - KakaoTalk sharing functionality

### Screen Structure
- `MainWorldCupScreen` - Tournament list and main navigation
- `AddWorldCupScreen` - Create new tournaments
- `PlayWorldCupScreen` - Tournament gameplay
- `ResultWorldCupScreen` - Tournament results with sharing
- `HelpScreen` - App introduction and help

### Database Schema
Two main tables:
- `worldcup_table`: Tournament metadata (idx, title, info, date, titleImageSrc, maxRound)
- `worldcup_item_table`: Tournament items (idx, imagePath, imageInfo, worldCupIdx)

## Configuration Requirements

### Environment Variables (.env)
The app requires a `.env` file in the root directory with:
- `kakao_nativeAppKey` - KakaoTalk native app key
- `kakao_javaScriptAppKey` - KakaoTalk JavaScript app key  
- `imgbb_apiKey` - ImgBB API key for image uploads

## Key Development Notes

- App is locked to portrait orientation
- Uses Material 3 design system with deep purple accent color
- Includes sample tournament data populated on first app launch
- Image uploads have 3-day expiration via ImgBB
- Tournament rounds are generated using binary elimination logic in `lib/tools/make_round.dart`
- Ad integration through Google Mobile Ads with helper classes in `lib/ad/`

## Coding Conventions (avoid reintroducing known lint/deprecation issues)

- **Back navigation interception**: Use `PopScope` with `onPopInvokedWithResult: (didPop, result) { ... }`, never `WillPopScope` (removed) or the deprecated `onPopInvoked` callback. Set `canPop: false` when the default pop must be intercepted (e.g., to show an ad or confirmation dialog first), and `return` early if `didPop` is already true.
- **Color opacity**: Use `color.withValues(alpha: x)`, never `color.withOpacity(x)` (deprecated, loses precision).
- **Logging**: Never use `print()` in `lib/`. Use `dart:developer`'s `log(message, error: e, name: 'source_name')` instead. If a file also imports `dart:math`, hide its `log` to avoid an `ambiguous_import` error: `import 'dart:math' hide log;`.
- **Widget fields**: All `StatelessWidget`/`StatefulWidget` instance fields must be declared `final`, and their constructors should be `const` whenever every field can be const-initialized. Do not add mutable fields to a widget class — put mutable state in the corresponding `State` class instead.
- **BuildContext across async gaps**: After any `await` inside a method that later uses `context` (navigation, `showDialog`, `ScaffoldMessenger`, etc.), guard with a mounted check before the first post-await context use: `if (!mounted) return;` inside a `State` method, or `if (!context.mounted) return;` when `context` is a parameter (e.g., a free function or a loop awaiting multiple times — check on every iteration).

## Asset Structure
- `assets/images/` - App UI images and help screens
- `assets/sample/female/` and `assets/sample/male/` - Sample tournament images
- `assets/icon/` - App launcher icon

## Testing
Standard Flutter test structure in `test/` directory with widget tests.