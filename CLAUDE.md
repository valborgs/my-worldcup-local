# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter tournament-style ("World Cup") game application called "내가 만든 월드컵" (My Custom World Cup). Users can create custom tournaments with their own images, play through elimination rounds, share results via KakaoTalk, and send whole tournaments to nearby devices.

**Key Technologies:**
- Flutter / Dart, organised as a **pub workspace** (Dart 3.13+)
- Riverpod for dependency injection and state
- SQLite (sqflite) for local storage
- ImgBB for image hosting, KakaoTalk SDK for sharing
- Google Mobile Ads, Firebase Remote Config
- Google Nearby Connections via a project-local plugin

## Development Commands

```bash
# Install dependencies (one pub get resolves the whole workspace)
flutter pub get

# Run the app
flutter run

# Analyze everything
flutter analyze

# Formatting (CI enforces this)
dart format lib packages test

# Tests: `flutter test` only runs the package it is pointed at,
# so the app and every package must be run explicitly.
flutter test
for dir in packages/*/; do flutter test "$dir"; done

# Build for release
flutter build apk --release
flutter build appbundle --release

# Generate launcher icons
flutter pub run flutter_launcher_icons:main
```

## Architecture

The app is split into packages so that several people can work on different
features without touching the same files. **Package boundaries are enforced by
the pub dependency graph, not by convention** — a package cannot import what is
not in its `pubspec.yaml`.

```
my-worldcup-local/            # pub workspace root = app shell
├─ lib/                       # assembly only: bootstrap + DI + router
├─ packages/
│  ├─ worldcup_core/          # pure Dart. Failures, routing contract, logging port
│  ├─ worldcup_domain/        # pure Dart. Entities, ports, port providers
│  ├─ worldcup_data/          # port implementations (sqflite, ImgBB, Kakao, AdMob, Firebase)
│  ├─ worldcup_ui_kit/        # shared widgets and theme
│  ├─ worldcup_nearby_transfer/  # Nearby Connections platform channel plugin
│  ├─ feature_worldcup_list/     # tournament list, cover-flow pager, bottom sheet, search
│  ├─ feature_worldcup_play/     # gameplay and result screens
│  ├─ feature_worldcup_editor/   # create and edit screens
│  └─ feature_worldcup_share/    # nearby send / receive
```

### Allowed dependency direction

```
app(lib)      ──> feature_* , worldcup_data , worldcup_ui_kit , worldcup_core , worldcup_domain
feature_*     ──> worldcup_domain , worldcup_ui_kit , worldcup_core (+ plugin packages)
worldcup_data ──> worldcup_domain , worldcup_core
worldcup_domain ──> worldcup_core
worldcup_core ──> (nothing)
```

Two rules matter most, and CI checks both:

1. **feature packages never depend on each other.** Screens reach each other
   only through the route contract (below).
2. **feature packages never depend on `worldcup_data`.** They receive
   implementations through the port providers declared in `worldcup_domain`.

`worldcup_core` and `worldcup_domain` must stay pure Dart — no
`package:flutter/` imports. They use the plain `riverpod` package (not
`flutter_riverpod`) so that port providers can live in the domain.

### Navigation: the route contract

Screens do not construct each other. `worldcup_core` owns route names
(`AppRoutes`) and typed argument classes; `lib/app_router.dart` is the only
place that binds a route name to a widget.

Route arguments carry **ids, not entities**. `worldcup_core` sits below
`worldcup_domain`, so it cannot reference entity types. Destination screens
load what they need from the repository.

```dart
Navigator.pushNamed(
  context,
  AppRoutes.play,
  arguments: PlayArgs(worldCupId: model.idx, round: selectedRound),
);
```

### Dependency injection

`worldcup_domain` declares provider handles for its ports
(`worldCupRepositoryProvider`, `worldCupPackageProvider`, `imageUploadProvider`,
`socialShareProvider`, `adUnitProvider`). They throw by default.
`lib/di/providers.dart` overrides every one of them with a `worldcup_data`
implementation, and that list is the app's only assembly point.

`main()` builds a `ProviderContainer` before `runApp` so bootstrap work (sample
seeding, first page load) shares the same instances the widget tree gets via
`UncontrolledProviderScope`.

### State

Screens with non-trivial state own a `ChangeNotifier` view model that holds the
logic and knows nothing about widgets, so it can be unit tested without
pumping:

- `WorldCupListViewModel` — pager paging, sheet infinite scroll, search
- `WorldCupEditorViewModel` — item list and save rules
- `MatchSelectionNotifier` (Riverpod) — which side the player tapped

### Database schema

- `worldcup_table`: idx, title, info, date, titleImageSrc, maxRound
- `worldcup_item_table`: idx, imagePath, imageInfo, worldCupIdx

Sample tournaments use **negative `idx`** and are wiped and re-seeded on every
launch from `assets/sample/sample_worldcups.json`. User tournaments have
positive ids and are never touched by seeding.

## Configuration

`.env` in the repository root:

- `kakao_nativeAppKey`, `kakao_javaScriptAppKey` — KakaoTalk
- `imgbb_apiKey` — ImgBB uploads
- `playstore_url` — link embedded in the shared Kakao card
- `admob_*UnitId` — ad unit ids (falls back to Google test ids)

Adapters never read `dotenv` themselves; the DI layer passes values into their
constructors so they stay testable.

## Key Development Notes

- Phones are locked to portrait; large screens (shortestSide ≥ 600dp) allow rotation.
- Material 3, deep purple seed colour, defined once in `worldcup_ui_kit`'s `AppTheme`.
- ImgBB uploads expire after 3 days.
- Round options come from `TournamentRounds` in `worldcup_domain`.
  `defaultRound()` derives from `available().last`, so it is always a power of two
  and always one of the selectable values. Keep it that way: the two used to carry
  separate rules, and the default could land on a value the dropdown did not offer
  (20 items → offered `[4, 8, 16]`, defaulted to 20), which crashed the game once
  the bracket reached an odd count. Tests in `worldcup_domain` pin the invariant.
- **Assets stay in the app package.** Moving them under `packages/` would change
  asset paths to `packages/<name>/...`, and those path strings are stored in the
  user's SQLite rows.
- Asset directory entries in `pubspec.yaml` are **not recursive**. Listing
  `assets/sample/female/` does not bundle `assets/sample/sample_worldcups.json`;
  the parent directory has to be listed too.

## Coding Conventions (avoid reintroducing known lint/deprecation issues)

- **Back navigation interception**: Use `PopScope` with `onPopInvokedWithResult: (didPop, result) { ... }`, never `WillPopScope` (removed) or the deprecated `onPopInvoked` callback. Set `canPop: false` when the default pop must be intercepted (e.g., to show an ad or confirmation dialog first), and `return` early if `didPop` is already true.
- **Color opacity**: Use `color.withValues(alpha: x)`, never `color.withOpacity(x)` (deprecated, loses precision).
- **Logging**: Never use `print()` in `lib/` or `packages/*/lib/`. Use `dart:developer`'s `log(message, error: e, name: 'source_name')`, or `AppLogger` from `worldcup_core` in the data layer. If a file also imports `dart:math`, hide its `log` to avoid an `ambiguous_import` error: `import 'dart:math' hide log;`.
- **Widget fields**: All `StatelessWidget`/`StatefulWidget` instance fields must be declared `final`, and their constructors should be `const` whenever every field can be const-initialized. Do not add mutable fields to a widget class — put mutable state in the corresponding `State` class instead.
- **BuildContext across async gaps**: After any `await` inside a method that later uses `context` (navigation, `showDialog`, `ScaffoldMessenger`, etc.), guard with a mounted check before the first post-await context use: `if (!mounted) return;` inside a `State` method, or `if (!context.mounted) return;` when `context` is a parameter (e.g., a free function or a loop awaiting multiple times — check on every iteration).
- **Riverpod lifecycle**: Never modify a provider during a widget lifecycle callback (`initState`, `build`, `dispose`) — Riverpod throws. Do it from an async callback or an event handler instead.
- **Null-coalescing with `ref.read`**: `widget.something ?? ref.read(provider)` infers a nullable `T` from the left operand and makes the whole expression nullable. Annotate the local explicitly: `final MyPort port = widget.something ?? ref.read(provider);`
- **Moving widget logic into a view model**: a `State` protects its async work with
  `mounted` checks and sometimes with a generation counter that invalidates in-flight
  requests. Those guards are easy to miss because they are not part of the visible
  behaviour — but dropping them is a regression. Carry each one across:
  - `if (!mounted) return;` after an `await` becomes a `_disposed` flag on the view
    model, checked before applying state, plus a `_notify()` wrapper that skips
    `notifyListeners()` once disposed. Without it the widget's `dispose` disposes the
    view model while a query is still in flight, and the response throws
    `A <Notifier> was used after being disposed`.
  - A generation counter (`_queryGeneration++`) that a cancel path bumped must keep
    bumping. Put it in the shared reset helper so every caller — cancel *and*
    refresh — is covered, not just the one you were looking at.

  Write the reproduction test before the fix and watch it fail; these paths are
  timing-dependent and a test that never actually failed proves nothing.

## Asset Structure

- `assets/images/` — app UI images and help screens
- `assets/icon/` — launcher icon
- `assets/sample/sample_worldcups.json` — sample tournament seed data
- `assets/sample/female/`, `assets/sample/male/` — sample tournament images

## Testing

Tests live in the package that owns the code under test.

- `test/` — app-level only: the route contract and the seed asset
- `packages/<name>/test/` — everything else

Prefer view-model unit tests over widget tests where the logic allows it; they
run without pumping and cover async ordering that widget tests cannot reach.

When a test verifies an asset, load it through `rootBundle`, not `File`.
Reading from disk passes even when the asset is missing from `pubspec.yaml`,
which is how a startup crash once shipped past a green test.
