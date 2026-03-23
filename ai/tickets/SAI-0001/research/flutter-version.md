# Research: Flutter Version Modernisation

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** Latest stable Flutter, Dart null safety, breaking changes, package upgrades

---

## 1. Latest Stable Flutter & Dart SDK

Flutter releases on a roughly quarterly cadence. The table below shows confirmed releases through mid-2025 and estimated releases into early 2026:

| Release | Approx Date | Dart SDK |
|---------|-------------|----------|
| Flutter 3.19 | Feb 2024 | Dart 3.3 |
| Flutter 3.22 | May 2024 | Dart 3.4 |
| Flutter 3.24 | Aug 2024 | Dart 3.5 |
| Flutter 3.27 | Nov 2024 | Dart 3.6 |
| Flutter 3.29 (est.) | Feb 2025 | Dart 3.7 |
| Flutter 3.32 (est.) | May 2025 | Dart 3.8 |
| **Flutter 3.35 (est. latest stable ~early 2026)** | **~Feb 2026** | **Dart 3.9–3.10** |

**Key sources:**
- https://docs.flutter.dev/release/whats-new
- https://docs.flutter.dev/release/release-notes
- https://github.com/flutter/flutter/releases

---

## 2. Flutter 1.x vs Flutter 3.x: Major Differences

| Area | Flutter 1.x (current project) | Flutter 3.x (target) |
|------|-------------------------------|----------------------|
| Dart null safety | Not available | Sound null safety — mandatory in Dart 3 |
| Platform support | iOS + Android | iOS, Android, Web, macOS, Windows, Linux (all stable) |
| Material Design | Material 2 only | Material 3 (M3) default since Flutter 3.16 |
| Rendering engine | Skia only | Impeller (default iOS 3.16+, Android 3.22+) |
| Buttons | `FlatButton`, `RaisedButton`, `OutlineButton` | `TextButton`, `ElevatedButton`, `OutlinedButton` |
| Navigation | Navigator 1.0 named routes | Navigator 2.0 / GoRouter recommended |
| State management | `StatefulWidget` + `setState` only | Riverpod, Bloc, Provider all mature and recommended |
| Android embedding | V1 (deprecated and removed) | V2 only |

---

## 3. Dart Null Safety Migration

### Timeline
- **Dart 2.12** (March 2021): Sound null safety introduced, opt-in
- **Dart 3.0** (May 2023): Null safety **mandatory** — code that is not null-safe will not compile
- **Dart 3.x (current)**: Adds records, patterns, class modifiers, macros (experimental)

### pubspec.yaml Change

```yaml
# Current project (no null safety)
environment:
  sdk: ">=2.1.0 <3.0.0"

# Target (Dart 3, null safety mandatory)
environment:
  sdk: ">=3.0.0 <4.0.0"
```

### Key Syntax Changes

```dart
// Old (Dart 2.x)
String name;           // implicitly nullable
int count = null;      // allowed
Database _database;    // nullable without annotation (used in current DBHandler)

// New (Dart 3.x)
String? name;          // explicitly nullable
String name = '';      // must be initialised
late Database _database; // non-nullable, initialised later
int count = 0;         // null not assignable
```

### Migration Tool

```bash
dart migrate
```

Available in the Dart SDK for assisted migration from Dart 2.x. Results require manual review.

**Source:** https://dart.dev/null-safety/migration-guide  
**Source:** https://dart.dev/resources/dart-3-migration

---

## 4. Breaking Changes: Flutter 1.x → 3.x

### A. Button Widgets — REMOVED in Flutter 3.x (compile errors)

| Removed | Replacement |
|---------|-------------|
| `FlatButton` | `TextButton` |
| `RaisedButton` | `ElevatedButton` |
| `OutlineButton` | `OutlinedButton` |
| `FlatButton.icon()` | `TextButton.icon()` |
| `RaisedButton.icon()` | `ElevatedButton.icon()` |
| `ButtonBar` | `OverflowBar` |

```dart
// Old
FlatButton(onPressed: () {}, child: Text('Cancel'))

// New
TextButton(onPressed: () {}, child: const Text('Cancel'))

// Old
RaisedButton(onPressed: () {}, color: Colors.blue, child: Text('Add'))

// New
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  onPressed: () {},
  child: const Text('Add'),
)
```

**Source:** https://docs.flutter.dev/release/breaking-changes/buttons

### B. Android Embedding V1 → V2

Flutter 3.x removed Android Embedding V1 entirely. The project's `MainActivity` must use V2 imports:

```kotlin
// Old V1 — REMOVED
import io.flutter.app.FlutterActivity

// New V2 — REQUIRED
import io.flutter.embedding.android.FlutterActivity
```

**Source:** https://docs.flutter.dev/release/breaking-changes/android-activity-control-surface-class

### C. SnackBar API

```dart
// Old — deprecated/broken in 3.x
Scaffold.of(context).showSnackBar(SnackBar(content: Text('Hello')));

// New
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Hello')));
```

### D. WillPopScope → PopScope (Flutter 3.12+)

```dart
// Old — removed in Flutter 3.16
WillPopScope(onWillPop: () async => true, child: ...)

// New
PopScope(canPop: true, child: ...)
```

### E. ThemeData — Material 3 property renames

| Old property | New property |
|---|---|
| `ThemeData.accentColor` | `ThemeData.colorScheme.secondary` |
| `ThemeData.backgroundColor` | `ThemeData.colorScheme.surface` |
| `TextTheme.headline1`–`headline6` | `displayLarge`, `titleLarge`, etc. |

**Source:** https://docs.flutter.dev/release/breaking-changes

---

## 5. `charts_flutter` — Abandoned; Replacements

### Status

`charts_flutter` (Google, pub.dev) was **abandoned by Google**:
- Last meaningful release: `0.12.0` (circa 2022)
- **Not Dart 3 compatible** — will not compile with Flutter 3.x / Dart 3
- GitHub repo archived; no Google response to issues since 2022
- pub.dev shows "discontinued" / unmaintained signals

**Source:** https://pub.dev/packages/charts_flutter  
**Source:** https://github.com/google/charts

### Recommended Replacements

| Package | Latest (Aug 2025) | Notes |
|---------|-------------------|-------|
| **`fl_chart`** | `^0.68.0` | Most popular (~7k GitHub stars), beautiful, highly customisable. Pie, bar, line, scatter. **Best general recommendation.** |
| `community_charts_flutter` | `^1.1.0+` | Drop-in replacement for `charts_flutter`. Easiest migration, ~95% API compatible. |
| `syncfusion_flutter_charts` | current | Enterprise-grade, extensive types. Free community licence for revenue < $1M USD. |
| `graphic` | current | Grammar of Graphics inspired. Powerful but steeper learning curve. |

**Source:** https://pub.dev/packages/fl_chart  
**Source:** https://pub.dev/packages/community_charts_flutter

---

## 6. Current Package Versions (targets)

| Package | Current Stable (Aug 2025) | Dart 3 Compatible |
|---------|---------------------------|-------------------|
| `sqflite` | `2.3.3+2` | Yes (since 2.0.0) |
| `path_provider` | `2.1.4` | Yes (since 2.0.0) |
| `cupertino_icons` | `1.0.8` | Yes |
| `fl_chart` | `0.68.0` | Yes |
| `flutter_lints` | `4.0.0` | Yes |

**pubspec.yaml target:**

```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.3
  path_provider: ^2.1.4
  fl_chart: ^0.68.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

**Sources:** https://pub.dev/packages/sqflite | https://pub.dev/packages/path_provider | https://pub.dev/packages/fl_chart

---

## 7. Android Build Configuration Requirements

### Minimum SDK

From Flutter 3.10+, the minimum Android API is **21** (Android 5.0 Lollipop). The project's current `minSdkVersion` must be updated.

```gradle
// android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21       // required for Flutter 3.10+
        targetSdkVersion 34
        compileSdkVersion 34
    }
}
```

**Source:** https://docs.flutter.dev/release/breaking-changes/android-api-requirements

### Android Gradle Plugin (AGP)

| Flutter version | Required AGP | Required Gradle |
|-----------------|-------------|----------------|
| Flutter 3.22+ | AGP 8.1+ | Gradle 8.3+ |

Current project uses AGP `3.5.0` / Gradle `?` — both must be updated significantly.

```gradle
// android/build.gradle
buildscript {
    ext.kotlin_version = '1.9.23'  // update from 1.3.50
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.2'  // update from 3.5.0
    }
    repositories {
        google()
        mavenCentral()  // replace jcenter() — deprecated/sunset
    }
}
```

```gradle
// android/app/build.gradle
android {
    namespace 'com.example.expense_tracker'  // required by AGP 8+
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }
}
```

**Note:** `jcenter()` was sunset in 2021. Must be replaced with `mavenCentral()` and `google()`.

**Source:** https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide

---

## 8. Linting: `analysis_options.yaml`

The project has no linting configuration. Adding `flutter_lints` is a standard Flutter project requirement.

```yaml
# analysis_options.yaml (project root)
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    use_key_in_widget_constructors: true
    avoid_print: true
    prefer_single_quotes: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true

analyzer:
  errors:
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

**Source:** https://pub.dev/packages/flutter_lints  
**Source:** https://dart.dev/tools/linter-rules

---

## Summary: Key Actions for This Project

| # | Action | File(s) |
|---|--------|---------|
| 1 | Update Dart SDK constraint to `>=3.0.0 <4.0.0` | `pubspec.yaml` |
| 2 | Update all package versions to current stable | `pubspec.yaml` |
| 3 | Replace `charts_flutter` with `fl_chart ^0.68.0` | `pubspec.yaml` + all chart widgets |
| 4 | Migrate all Dart files to null safety | All `lib/**/*.dart` |
| 5 | Replace `FlatButton`/`RaisedButton` | `form_page.dart`, `form_layout.dart` |
| 6 | Update Android embedding to V2 | `android/app/src/main/...` |
| 7 | Update AGP to 8.1+, Kotlin to 1.9.x, Java 17 | `android/build.gradle`, `android/app/build.gradle` |
| 8 | Replace `jcenter()` with `mavenCentral()` | `android/build.gradle` |
| 9 | Add `namespace` to app `build.gradle` | `android/app/build.gradle` |
| 10 | Add `analysis_options.yaml` with flutter_lints | project root |

---

## Sources

| Topic | URL |
|-------|-----|
| Flutter release notes | https://docs.flutter.dev/release/whats-new |
| Flutter breaking changes index | https://docs.flutter.dev/release/breaking-changes |
| Dart null safety migration | https://dart.dev/null-safety/migration-guide |
| Dart 3 migration guide | https://dart.dev/resources/dart-3-migration |
| Flutter buttons deprecation | https://docs.flutter.dev/release/breaking-changes/buttons |
| Android embedding V2 | https://docs.flutter.dev/release/breaking-changes/android-activity-control-surface-class |
| Android min SDK | https://docs.flutter.dev/release/breaking-changes/android-api-requirements |
| Android Gradle migration | https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide |
| `charts_flutter` (abandoned) | https://pub.dev/packages/charts_flutter |
| `fl_chart` | https://pub.dev/packages/fl_chart |
| `community_charts_flutter` | https://pub.dev/packages/community_charts_flutter |
| `sqflite` | https://pub.dev/packages/sqflite |
| `path_provider` | https://pub.dev/packages/path_provider |
| `cupertino_icons` | https://pub.dev/packages/cupertino_icons |
| `flutter_lints` | https://pub.dev/packages/flutter_lints |
| Dart linter rules | https://dart.dev/tools/linter-rules |
