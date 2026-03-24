# Current State Audit: Flutter Expense Tracker

> Audit performed: March 2026. Branch: `claude/flutter-modernization-research-FmbLj`.

---

## 1. Project Overview

A Flutter mobile expense tracker that stores data locally in SQLite. The app allows users to:
- Add expenses with item name, category, cost, and date
- View analytics (pie chart by category)
- Browse expense history
- Filter by date range

The app is a single developer's personal project in early/prototype state with no automated testing or CI/CD.

---

## 2. Technical Stack (Current)

| Concern | Current Implementation |
|---|---|
| Flutter SDK | 2.x era (SDK constraint `>=2.1.0 <3.0.0`) |
| Dart language | Pre-Dart 3 (no sealed classes, records, or patterns) |
| Database | `sqflite ^1.3.0` (very old; current is 2.x) |
| Charts | `charts_flutter ^0.9.0` (**discontinued** by Google) |
| State management | Raw `setState` + `StatefulWidget` |
| Navigation | Named routes (string-based, `Navigator.pushNamed`) |
| Path resolution | `path_provider ^0.4.1` (very old; current is 2.x) |
| Icons | `cupertino_icons ^0.1.2` (very old; current is 1.x) |
| Theming | Hardcoded `ThemeData(brightness: Brightness.dark, primaryColor: Colors.cyan[800])` |
| Error handling | None — no `try/catch`, no `Result` types |
| Logging | Raw `print()` statements (a few commented out) |
| Testing | `test: any` in dev_dependencies, but no test files |
| CI/CD | None |
| Code generation | None |
| Accessibility | None |
| Localization | None — hardcoded English strings throughout |

---

## 3. File Structure

```
lib/
  app/
    column_labels.dart        # String constants for DB column names
  db_handler/
    handlers/
      db_handler.dart         # Singleton DB access class (raw sqflite)
    models/
      category_cost_sums_model.dart
      expense_model.dart      # Mutable Expense class with manual getters/setters
      item_cost_sums_model.dart
  pages/
    form_page.dart            # Add expense form
    history_page.dart         # Expense history list
    home_page.dart            # Home screen with analytics
  widgets/
    drawer_widget.dart        # Navigation drawer
    form_layout.dart          # Form widget
    home_screen.dart          # Home screen content
    pie_chart_widget.dart     # Category pie chart
    table_widget.dart         # Expense data table
  main.dart                   # App entry point and routing
```

---

## 4. Critical Issues

### 4.1 Discontinued Package: `charts_flutter`

`charts_flutter ^0.9.0` was **deprecated and abandoned by Google** in 2022. The package no longer receives updates and is incompatible with current Flutter SDK versions.

**Impact:** The app cannot be built with a current Flutter SDK. This is a blocking issue.

**Replacement options:**
- `fl_chart` (https://pub.dev/packages/fl_chart) — most popular, actively maintained, excellent M3 support
- `syncfusion_flutter_charts` — commercial but comprehensive
- `graphic` — grammar-of-graphics approach

**Recommended replacement:** `fl_chart` — it has the best combination of API quality, active maintenance, and Flutter community adoption.

### 4.2 Dart SDK Constraint Blocks Dart 3

```yaml
environment:
  sdk: ">=2.1.0 <3.0.0"  # Blocks Dart 3
```

This blocks Dart 3 features: sealed classes, records, pattern matching, `switch` expressions, class modifiers, and the updated standard library. All research recommendations depend on Dart 3.

**Fix:** Update to `sdk: ">=3.3.0 <4.0.0"` (or current stable).

### 4.3 No Error Handling

`DBHandler` performs all database operations without any `try/catch`. Errors surface as unhandled exceptions that crash the app.

```dart
// Current: no error handling
Future<int> insert(Expense expense) async {
  Database db = await database;
  int id = await db.insert(tableExpenses, expense.toMap());
  return id;
}
```

### 4.4 Nullable Field Without Null Safety

The `_database` field in `DBHandler` is declared as `static Database _database` — a non-nullable type that is `null` until initialized. This compiled under the pre-null-safety Dart 2.1 constraint but will fail under Dart 3 null safety.

Similar issue: `Expense._id` is assigned in `fromMap` but not in the main constructor, making it implicitly null.

### 4.5 No State Management

All state is held in `StatefulWidget` with `setState`. The `_HomeState` class has a nearly empty `build()` method with a TODO comment and no state — business logic would need to be added here without a clear pattern.

As the app grows, `setState` in a single widget becomes unmanageable.

### 4.6 `print()` for Logging

Multiple `print()` statements appear in `db_handler.dart`. These:
- Appear in release builds
- Have no log level filtering
- Cannot be selectively enabled/disabled

### 4.7 Old Package Versions (Incompatible with Current Flutter)

| Package | Current | Latest Stable | Note |
|---|---|---|---|
| `sqflite` | ^1.3.0 | ^2.3.x | Breaking changes in 2.x |
| `path_provider` | ^0.4.1 | ^2.3.x | Plugin API changed |
| `charts_flutter` | ^0.9.0 | **Abandoned** | Must replace |
| `cupertino_icons` | ^0.1.2 | ^1.0.x | Minor update |

### 4.8 No `const` Widgets

No `const` constructors are used anywhere in the widget tree. Every rebuild allocates new widget instances unnecessarily.

### 4.9 Hard-Coded Strings Throughout

All user-facing strings (button labels, dialog text, error messages) are hard-coded English literals. There is no centralized string management.

### 4.10 Non-M3 Theme

The current theme uses deprecated APIs:
```dart
ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.cyan[800],  // primaryColor is deprecated in M3
)
```

`primaryColor` is not used by most M3 widgets. The correct approach is `ColorScheme.fromSeed`.

---

## 5. Code Quality Issues

### 5.1 `TODO` Comments as Placeholders

```dart
@override
Widget build(BuildContext context) {
  // TODO: implement build
  return homePage(context);
}
```

The build method is implemented but retains the IDE-generated TODO.

### 5.2 Mutable Model with Private Fields + Manual Getters

The `Expense` class uses private fields with manual getters/setters — a Java-style pattern. Dart's `freezed` or a simple `const` class achieves the same immutability with far less boilerplate.

```dart
// Current (34 lines of getters/setters)
String get item => _item;
int get id => _id;
double get cost => _cost;
// ...

// Modern (6 lines, immutable, has copyWith and == for free)
@freezed
class Expense with _$Expense {
  const factory Expense({int? id, required String item, required String category,
    required double cost, required DateTime date}) = _Expense;
}
```

### 5.3 Non-Standard DB Pattern (Singleton with Static Mutable State)

`DBHandler` uses a static singleton with a nullable `static Database _database` field. This pattern:
- Is hard to test (cannot inject a mock/in-memory DB)
- Cannot be auto-disposed or cleaned up in tests
- Creates tight coupling between the DB layer and every consumer

### 5.4 Business Logic in `DBHandler`

`DBHandler` handles both connection management AND query logic. Queries like `getCategoryCostSums()` and `getTotalCostSince()` belong in a repository layer, not the connection manager.

### 5.5 `fromMappedList` is Unused

The `fromMappedList` helper in `DBHandler` is commented out at its call site and creates a dummy `Expense("None", "category", 0, now)` when the list is empty — this is bug-prone sentinel value logic.

---

## 6. Missing Infrastructure

| Concern | Status |
|---|---|
| Unit tests | None |
| Widget tests | None |
| Integration tests | None |
| CI pipeline | None |
| CD / release automation | None |
| Code formatting config | None (`analysis_options.yaml` missing) |
| Lint rules | None |
| `.gitignore` for generated files | Not checked |

---

## 7. Summary: Risk Assessment

| Risk | Severity | Blocking? |
|---|---|---|
| `charts_flutter` is abandoned | Critical | Yes — cannot build with current Flutter |
| Dart SDK constraint blocks Dart 3 | Critical | Yes — blocks all modern APIs |
| Old package versions incompatible | Critical | Yes — build will fail |
| No error handling | High | No — but causes silent crashes |
| No tests | High | No — but makes refactoring risky |
| No state management | Medium | No — manageable at current scope |
| `print()` logging | Low | No |
| No CI/CD | Low | No — but risk grows with time |
| Hard-coded strings | Low | No |

---

## 8. Positive Aspects

- Clear separation between DB layer and UI layer (pages vs widgets vs db_handler)
- DB schema is simple and well-defined
- `column_labels.dart` centralizes DB schema constants (avoids string literal duplication)
- `DBHandler` has reasonable Dart-doc comments describing each method
- The app has a clear, small scope — modernization is achievable without a full rewrite
