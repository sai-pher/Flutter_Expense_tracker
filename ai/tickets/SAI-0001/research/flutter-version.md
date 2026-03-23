# Research: Flutter Version Modernisation

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** Latest stable Flutter, Dart null safety, breaking changes, package upgrades  
> **Sources:** flutter.dev, pub.dev, github.com/flutter/flutter, dart.dev

---

## 1. Latest Stable Flutter & Dart SDK

**Latest stable Flutter (as of March 2026): Flutter 3.41.5** (released March 17, 2026)  
**Bundled Dart SDK:** 3.9.x

Flutter releases on a roughly quarterly cadence:

| Release | Approx Date | Dart SDK | Key change |
|---------|-------------|----------|------------|
| Flutter 2.0 | Mar 2021 | Dart 2.12 | Null safety (opt-in), web stable |
| Flutter 3.0 | May 2022 | Dart 2.17 | Stable desktop |
| Flutter 3.10 | May 2023 | Dart 3.0 | Null safety mandatory, minSdk 21 |
| Flutter 3.16 | Nov 2023 | Dart 3.2 | Material 3 default, Impeller iOS default |
| Flutter 3.22 | May 2024 | Dart 3.4 | Impeller Android, AGP 7.3+ |
| Flutter 3.27 | Nov 2024 | Dart 3.6 | — |
| Flutter 3.29 | Feb 2025 | Dart 3.7 | AGP 8.7.0, compileSdk 35 |
| **Flutter 3.41.5** | **Mar 2026** | **Dart 3.9** | **minSdk 24, AGP 8.11.1, compileSdk 36** |

**Sources:**
- https://docs.flutter.dev/release/whats-new
- https://github.com/flutter/flutter/releases

---

## 2. Flutter 1.x vs Flutter 3.41.x: Major Differences

| Area | Flutter 1.x (current project) | Flutter 3.41.x (target) |
|------|-------------------------------|-------------------------|
| Null safety | Not available | Mandatory (Dart 3.0+) |
| Platforms | iOS + Android | iOS, Android, Web, macOS, Windows, Linux |
| Material Design | Material 2 | Material 3 default (since 3.16) |
| Rendering | Skia only | Impeller (default on iOS and Android) |
| Buttons | `FlatButton`, `RaisedButton` | `TextButton`, `ElevatedButton` |
| Navigation | Named routes (Navigator 1.0) | `GoRouter` / Navigator 2.0 |
| Android embedding | V1 (removed) | V2 only |
| minSdkVersion | 16 | **24** (Android 7.0 Nougat) |
| AGP | 3.5.0 | **8.11.1** |
| Kotlin | 1.3.50 | 1.9.x or 2.0.x |

---

## 3. Dart Null Safety Migration

### Timeline
- **Dart 2.12** (March 2021): Sound null safety — opt-in
- **Dart 3.0** (May 2023, Flutter 3.10): Null safety **mandatory** — code without it will not compile
- **Dart 3.9** (current): Additional type promotion improvements; new lint rules

### pubspec.yaml Change Required

```yaml
# Current project (pre-null safety)
environment:
  sdk: ">=2.1.0 <3.0.0"

# Target
environment:
  sdk: ">=3.0.0 <4.0.0"
```

### Key Syntax Changes

```dart
// Old (Dart 2.x, no null safety)
String name;            // implicitly nullable
int count = null;       // allowed
Database _database;     // nullable without annotation

// New (Dart 3.x)
String? name;           // explicitly nullable
String name = '';       // must be initialised
late Database _database;// non-nullable, initialised later
int count = 0;          // null not assignable
```

The `DBHandler` class in this project uses `static Database _database;` — this must become `static Database? _database;` or use late initialisation.

**Source:** https://dart.dev/null-safety/migration-guide  
**Source:** https://dart.dev/resources/dart-3-migration

---

## 4. Breaking Changes: Flutter 1.x → 3.41.x

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
RaisedButton(onPressed: () {}, child: Text('Add'))

// New
TextButton(onPressed: () {}, child: const Text('Cancel'))
ElevatedButton(onPressed: () {}, child: const Text('Add'))
```

**Source:** https://docs.flutter.dev/release/breaking-changes/buttons

### B. Android Embedding V1 → V2 (mandatory)

```kotlin
// Old (V1 — REMOVED)
import io.flutter.app.FlutterActivity

// New (V2 — REQUIRED)
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity()
```

**Source:** https://docs.flutter.dev/release/breaking-changes/android-activity-control-surface-class

### C. ThemeData — Material 3 renames

| Old | New |
|-----|-----|
| `theme.accentColor` | `theme.colorScheme.secondary` |
| `ThemeData.primaryColor` (primary) | `theme.colorScheme.primary` |
| `TextTheme.headline1` | `TextTheme.displayLarge` |
| `TextTheme.bodyText2` | `TextTheme.bodyMedium` |

### D. minSdkVersion raised

| Flutter version range | minSdkVersion |
|----------------------|---------------|
| 1.x – 3.21 | 16 |
| 3.22 – 3.40 | 21 |
| **3.41+** | **24** |

### E. Other deprecated APIs

```dart
// Scaffold snackbar
Scaffold.of(context).showSnackBar(...)  →  ScaffoldMessenger.of(context).showSnackBar(...)

// Back navigation
WillPopScope(...)  →  PopScope(...)  // Flutter 3.12+

// Efficient MediaQuery
MediaQuery.of(context).size  →  MediaQuery.sizeOf(context)  // Flutter 3.10+
```

**Source:** https://docs.flutter.dev/release/breaking-changes

---

## 5. `charts_flutter` — Discontinued

`charts_flutter` is **officially discontinued** on pub.dev:
- Last version: `0.12.0` — published November 2021
- **Not null-safe** — will not compile on Dart 3.x / Flutter 3.10+
- Google archived the repository; no maintenance or response to issues since 2022

### Recommended Replacements

| Package | Latest | License | Notes |
|---------|--------|---------|-------|
| **`fl_chart`** | **1.2.0** | MIT | Best overall choice. Pie, bar, line, scatter, radar. 7k+ likes on pub.dev. Actively maintained. |
| `community_charts_flutter` | 1.0.4 | Apache-2.0 | Drop-in replacement; ~95% API compatible with `charts_flutter`. Easiest migration. |
| `syncfusion_flutter_charts` | 33.x | Commercial* | 30+ chart types; free community licence for revenue < $1M USD. |

**Recommendation:** Use `fl_chart ^1.2.0` for this project. It covers pie charts (current need) and is MIT licensed.

**Source:** https://pub.dev/packages/charts_flutter (discontinued badge)  
**Source:** https://pub.dev/packages/fl_chart  
**Source:** https://pub.dev/packages/community_charts_flutter

---

## 6. Target Package Versions (March 2026)

| Package | Latest Stable | Dart 3 | Notes |
|---------|--------------|--------|-------|
| `sqflite` | **2.4.2** | Yes (since 2.0.0) | Flutter Favorite; federated plugin |
| `path_provider` | **2.1.5** | Yes | Flutter Favorite; published by flutter.dev |
| `cupertino_icons` | **1.0.8** | Yes | Published by flutter.dev |
| `fl_chart` | **1.2.0** | Yes | Replaces charts_flutter |
| `flutter_lints` | **6.0.0** | Yes (Dart 3.8+) | Dev dependency |

**pubspec.yaml target:**

```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.4.2
  path_provider: ^2.1.5
  fl_chart: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

**Sources:** pub.dev for each package listed above.

---

## 7. Android Build Configuration Requirements

### Android Gradle Plugin (AGP)

```gradle
// android/build.gradle (project level)
buildscript {
    ext.kotlin_version = '1.9.23'  // was 1.3.50
    repositories {
        google()
        mavenCentral()  // replaces jcenter() — sunset in 2021
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.11.1'  // was 3.5.0
    }
}
```

### App build.gradle

```gradle
// android/app/build.gradle
android {
    namespace 'com.example.expense_tracker'  // required by AGP 8+
    compileSdk 36

    defaultConfig {
        minSdk 24              // was 16; Flutter 3.41+ requires 24
        targetSdk 36
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17  // was not set
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
}
```

### Gradle Wrapper

```properties
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip
```

**Key notes:**
- `jcenter()` was sunset; must be replaced with `mavenCentral()`
- AGP 8+ requires a `namespace` declaration in app `build.gradle`
- Java 17 is now the standard compile target

**Source:** https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide

---

## 8. Linting: `analysis_options.yaml`

The project has no linting configuration. All new Flutter projects scaffold this by default.

```yaml
# analysis_options.yaml (project root)
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    avoid_print: true          # catches leftover print() calls
    prefer_single_quotes: true
    use_key_in_widget_constructors: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
```

**`flutter_lints` version history:**

| Version | Min Dart | Notable |
|---------|----------|---------|
| 3.0.x | 3.1 | Stable baseline |
| 4.0.0 | 3.1 | `library_annotations`, `no_wildcard_variable_uses` |
| 5.0.0 | 3.5 | Removed `prefer_const_constructors`; added `unnecessary_library_name` |
| **6.0.0** | **3.8** | **`strict_top_level_inference`, `unnecessary_underscores`** |

**Source:** https://pub.dev/packages/flutter_lints  
**Source:** https://dart.dev/tools/linter-rules

---

## 9. Summary: Migration Actions for This Project

| # | Area | Current state | Required action |
|---|------|--------------|----------------|
| 1 | Dart SDK | `>=2.1.0 <3.0.0` | Update to `>=3.0.0 <4.0.0` |
| 2 | Flutter SDK | 1.x | Install Flutter 3.41.x (stable channel) |
| 3 | Null safety | None | Migrate all `.dart` files to null safety |
| 4 | `charts_flutter` | `^0.9.0` | Replace with `fl_chart ^1.2.0` |
| 5 | `sqflite` | `^1.3.0` | Update to `^2.4.2` |
| 6 | `path_provider` | `^0.4.1` | Update to `^2.1.5` |
| 7 | `cupertino_icons` | `^0.1.2` | Update to `^1.0.8` |
| 8 | `FlatButton` / `RaisedButton` | In use | Replace with `TextButton` / `ElevatedButton` |
| 9 | Android embedding | V1 | Migrate to V2 |
| 10 | `minSdkVersion` | 16 (assumed) | Raise to 24 |
| 11 | AGP | 3.5.0 | Update to 8.11.1 |
| 12 | Kotlin | 1.3.50 | Update to 1.9.23 |
| 13 | `jcenter()` | In use | Replace with `mavenCentral()` |
| 14 | Java target | Not set | Set to `VERSION_17` |
| 15 | `analysis_options.yaml` | Missing | Add with `flutter_lints ^6.0.0` |

---

## Sources

| Topic | URL |
|-------|-----|
| Flutter release notes | https://docs.flutter.dev/release/whats-new |
| Flutter GitHub releases | https://github.com/flutter/flutter/releases |
| Flutter breaking changes index | https://docs.flutter.dev/release/breaking-changes |
| Dart null safety migration | https://dart.dev/null-safety/migration-guide |
| Dart 3 migration guide | https://dart.dev/resources/dart-3-migration |
| Flutter buttons deprecation | https://docs.flutter.dev/release/breaking-changes/buttons |
| Android embedding V2 | https://docs.flutter.dev/release/breaking-changes/android-activity-control-surface-class |
| Android min SDK | https://docs.flutter.dev/release/breaking-changes/android-api-requirements |
| Android Gradle migration | https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide |
| `charts_flutter` (discontinued) | https://pub.dev/packages/charts_flutter |
| `fl_chart` | https://pub.dev/packages/fl_chart |
| `sqflite` | https://pub.dev/packages/sqflite |
| `path_provider` | https://pub.dev/packages/path_provider |
| `flutter_lints` | https://pub.dev/packages/flutter_lints |
| Dart linter rules | https://dart.dev/tools/linter-rules |
