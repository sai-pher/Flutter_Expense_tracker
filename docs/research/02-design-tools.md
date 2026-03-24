# Research: Modern Flutter Design Tools and Design Systems

> Research scope: Figma + Flutter plugins, FlutterFlow, Widgetbook, Material Design 3, design tokens.

---

## 1. Figma as the Primary Design Tool

Figma is the industry-standard design tool for Flutter projects in 2025. It integrates with Flutter through several paths:

### Figma Dev Mode

Figma's built-in Dev Mode (available in paid plans and free for developers in inspect mode) surfaces:
- Exact spacing, padding, and sizing values
- Typography (font family, size, weight, line height)
- Color hex values and opacity
- Export paths for assets

These values map directly to Flutter's `TextStyle`, `EdgeInsets`, `BorderRadius`, and `Color` constructors.

### Figma-to-Flutter Plugins

**Official Flutter Figma plugin:**
- Plugin ID: 1138492631953163970 (Figma community)
- Converts Figma Auto Layout frames to Flutter `Column`/`Row`/`Container` widget code
- Output requires manual cleanup but provides a useful starting point for layout structure
- Source: https://www.figma.com/community/plugin/1138492631953163970/flutter

**figmage CLI:**
- Reads a Figma file via the Figma API and generates Dart classes for colors, text styles, and spacing
- Source: https://pub.dev/packages/figmage

### Design Token Workflow with Figma

1. Designer defines tokens in **Tokens Studio for Figma** (https://tokens.studio/) using Figma Variables
2. Tokens exported as `tokens.json` in W3C Design Token format
3. **Style Dictionary** (https://amzn.github.io/style-dictionary/) transforms tokens to Dart constants
4. Generated Dart file is committed to the repo or regenerated in CI

This closes the design-to-code loop: token changes in Figma flow into typed Dart constants automatically.

### Recommended Figma Workflow for This Project

1. Define the app's color scheme, typography, and spacing in a Figma file
2. Use Material Design 3 Figma Kit (Google's official M3 component library for Figma)
3. Use Dev Mode for developer inspection during implementation
4. Define Figma Variables for color/spacing tokens → export → `app_colors.dart`, `app_spacing.dart`

---

## 2. FlutterFlow

**Website:** https://flutterflow.io
**Docs:** https://docs.flutterflow.io/

FlutterFlow is a visual, low-code Flutter builder that can generate a full Flutter project.

### Capabilities

- Drag-and-drop canvas with real-time Flutter preview (compiled Flutter, not simulation)
- Built-in Material 3 and Cupertino widget library
- Firebase integration (Firestore, Auth, Storage)
- Navigation flow designer
- Exports the entire app as a standard Flutter + Dart project

### Appropriate Use Cases

- Rapid MVP prototyping for stakeholder review
- Non-developer-led design exploration
- Generating boilerplate for standard screens that will be polished manually

### Limitations for This Project

- Exported code is verbose and uses FlutterFlow-specific patterns
- State management is `setState`-based; complex logic requires manual Dart editing
- Once you edit exported code locally, syncing back to FlutterFlow is difficult
- Not well-suited for clean architecture or custom state management patterns

**Verdict:** Not the right tool for this modernization project. The app has existing business logic and a defined architecture direction. FlutterFlow is most valuable for greenfield, design-first projects.

---

## 3. Widgetbook: Component-Driven Development

**Package:** https://pub.dev/packages/widgetbook
**Docs:** https://docs.widgetbook.io
**Annotation package:** https://pub.dev/packages/widgetbook_annotation

### What It Is

Widgetbook is Flutter's equivalent of Storybook.js. It enables developing, documenting, and visually testing widgets in isolation.

### How It Works

A separate Flutter entrypoint (the "widgetbook app") runs alongside the main app. Widgets are annotated with `@UseCase` to register them in the catalog.

```dart
// widgetbook/lib/expense_card.widgetbook.dart
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
part 'expense_card.widgetbook.g.dart';

@UseCase(name: 'Default', type: ExpenseCard)
Widget buildExpenseCardDefault(BuildContext context) {
  return ExpenseCard(
    amount: context.knobs.double.input(label: 'Amount', initialValue: 42.0),
    category: context.knobs.string(label: 'Category', initialValue: 'Food'),
    date: DateTime.now(),
  );
}

@UseCase(name: 'High amount', type: ExpenseCard)
Widget buildExpenseCardHighAmount(BuildContext context) {
  return ExpenseCard(amount: 9999.99, category: 'Travel', date: DateTime.now());
}
```

Running `dart run build_runner build` generates the catalog routing.

### Key Features

- **Knobs:** Interactive controls to adjust widget properties (strings, booleans, doubles, color pickers) at runtime
- **Device Frame Addon:** Preview widgets on different device form factors (iPhone 15, Pixel 8, etc.)
- **Theme Addon:** Toggle between light/dark or multiple custom themes
- **Accessibility Addon:** Integrates `accessibility_tools` checks inline
- **Widgetbook Cloud (paid):** Visual regression testing, Figma design integration, PR review workflow

### Value for This Project

Even as a solo developer, Widgetbook is useful for:
- Building complex widgets (expense list cards, charts, category chips) without navigating the full app
- Ensuring all widget states (empty, loading, error, populated) are covered
- Validating that widgets look correct across light/dark themes and device sizes

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  widgetbook: ^3.x.x
  widgetbook_annotation: ^3.x.x
  widgetbook_generator: ^3.x.x
  build_runner: ^2.4.x
```

---

## 4. Material Design 3 (Material You) in Flutter

**Official docs:** https://m3.material.io/develop/flutter
**Flutter M3 guide:** https://docs.flutter.dev/ui/design/material

### Enabling M3

As of Flutter 3.16, `useMaterial3: true` is the **default**. For older projects upgrading, explicitly set it:

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF005FAD),
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF005FAD),
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
)
```

### ColorScheme.fromSeed

M3 introduces a tonal color system generated from a single seed color:
- `ColorScheme.fromSeed(seedColor: color)` generates 30 color roles automatically
- Key roles: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondary`, `surface`, `onSurface`, `error`, `outline`, `surfaceVariant`
- All M3 widgets use these roles by default — no manual color passing needed

### Material Color Utilities

The underlying algorithm that powers `ColorScheme.fromSeed`:
- Source: https://pub.dev/packages/material_color_utilities

### Dynamic Color (Material You, Android 12+)

```dart
// pubspec.yaml: dynamic_color: ^1.7.x
import 'package:dynamic_color/dynamic_color.dart';

DynamicColorBuilder(
  builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightDynamic ?? fallbackLightScheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkDynamic ?? fallbackDarkScheme,
      ),
    );
  },
)
```

Source: https://pub.dev/packages/dynamic_color

### M3 TextTheme (Type Scale)

M3 defines 15 text roles:

| Role | Typical Use |
|---|---|
| `displayLarge/Medium/Small` | Large hero text, splash screens |
| `headlineLarge/Medium/Small` | Screen titles, section headers |
| `titleLarge/Medium/Small` | Card titles, dialog titles |
| `bodyLarge/Medium/Small` | Main content text |
| `labelLarge/Medium/Small` | Button labels, captions, chips |

Access: `Theme.of(context).textTheme.bodyMedium`

### M3 Components (Updated in Flutter 3.x)

| Old Widget | M3 Replacement |
|---|---|
| `BottomNavigationBar` | `NavigationBar` |
| `Drawer` (manual) | `NavigationDrawer` |
| `RaisedButton` | `FilledButton` |
| `FlatButton` | `TextButton` |
| `OutlineButton` | `OutlinedButton` |
| Custom chips | `FilterChip`, `InputChip`, `ActionChip` |
| `AlertDialog` | `AlertDialog` (M3 style automatic) |

### M3 Component Demo

Interactive Flutter M3 component catalog: https://flutter.github.io/samples/web/material_3_demo/

---

## 5. Defining a Design System in Flutter

### ThemeData as a Design System Container

All global design decisions should live in `ThemeData` and be inherited by all widgets via `Theme.of(context)`.

**Recommended structure:**

```
lib/
  core/
    theme/
      app_theme.dart        // ThemeData.light() and ThemeData.dark()
      app_colors.dart       // ColorScheme + custom brand colors
      app_text_styles.dart  // TextTheme definitions
      app_spacing.dart      // Spacing constants (4, 8, 16, 24, 32)
      app_radius.dart       // BorderRadius constants
```

### FlexColorScheme (Recommended Package)

**Package:** https://pub.dev/packages/flex_color_scheme

FlexColorScheme solves a real Flutter problem: `ThemeData` factories don't fully propagate `ColorScheme` colors to all legacy widget properties. FlexColorScheme ensures complete consistency.

```dart
import 'package:flex_color_scheme/flex_color_scheme.dart';

final lightTheme = FlexThemeData.light(
  scheme: FlexScheme.mandyRed,
  useMaterial3: true,
);

final darkTheme = FlexThemeData.dark(
  scheme: FlexScheme.mandyRed,
  useMaterial3: true,
);
```

**Themes Playground:** https://rydmike.com/flexcolorscheme/themesplayground-v8/
Visually configure a theme and export ready-to-paste Dart code.

### Material Theme Builder

Google's official tool: https://m3.material.io/theme-builder
Input a seed color → generates a full M3 color scheme → export as Flutter/Dart code.

---

## 6. Design Tokens in Flutter

Design tokens are named, platform-agnostic design decisions (colors, spacing, radii, durations).

### Option A: Manual Dart Constants (Recommended for Small Teams)

```dart
// lib/core/theme/app_spacing.dart
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// lib/core/theme/app_radius.dart
abstract class AppRadius {
  static const double sm = 4.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 28.0;
  static const Radius circularMd = Radius.circular(md);
  static const BorderRadius allMd = BorderRadius.all(circularMd);
}
```

### Option B: flutter_gen for Type-Safe Assets

**Package:** https://pub.dev/packages/flutter_gen

Generates type-safe Dart classes from asset files, eliminating runtime `'assets/images/logo.png'` string errors:

```dart
// Before
Image.asset('assets/images/logo.png')

// After (compile-time safe)
Assets.images.logo.image()
```

### Option C: Export from Figma via Style Dictionary

1. Export tokens from Figma Tokens/Variables as JSON
2. Run Style Dictionary to generate `lib/gen/tokens.dart`
3. Integrate into CI for automated updates

Source: https://amzn.github.io/style-dictionary/

---

## 7. Design Tool Summary

| Tool | Role | Best For |
|---|---|---|
| Figma | UI/UX design & handoff | Primary design source of truth |
| Figma Dev Mode | Developer inspection | Color/spacing value extraction |
| Tokens Studio (Figma plugin) | Design token management | Figma-to-code token pipeline |
| FlutterFlow | Low-code builder | Rapid prototyping, non-technical designers |
| Widgetbook | Component catalog | Component-driven development, UI review |
| Material Theme Builder | Color scheme generator | M3 theme setup starting point |
| FlexColorScheme | Theming package | Complete, consistent M3 ThemeData |
| flutter_gen | Asset code generation | Type-safe asset references |
| Zeplin | Design handoff (legacy) | Large orgs with separate design/dev teams |

---

## Sources

- https://m3.material.io/develop/flutter
- https://docs.flutter.dev/ui/design/material
- https://docs.widgetbook.io/
- https://pub.dev/packages/widgetbook
- https://pub.dev/packages/flex_color_scheme
- https://pub.dev/packages/dynamic_color
- https://pub.dev/packages/material_color_utilities
- https://pub.dev/packages/flutter_gen
- https://pub.dev/packages/figmage
- https://m3.material.io/theme-builder
- https://tokens.studio/
- https://amzn.github.io/style-dictionary/
- https://flutter.github.io/samples/web/material_3_demo/
