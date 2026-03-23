# Architecture Overview

> **Status:** Current state as of SAI-0001 (pre-modernisation).  
> This document will be updated as the app evolves.

## Purpose

Expense Tracker is a **local-only** mobile application for recording and analysing personal expenses. There is no backend, no authentication, and no cloud sync. All data is persisted on-device using SQLite.

### Core User Flows

1. **Record an expense** – user taps a FAB, fills in a form (item name, cost, category), and the record is saved to SQLite.
2. **View analytics** – home screen displays charts (pie chart) and tables showing spending broken down by category, item, and time period.
3. **History** – a dedicated page for viewing the raw list of recorded expenses (partially implemented).

---

## Tech Stack (current)

| Layer | Technology |
|---|---|
| Language | Dart `>=2.1.0 <3.0.0` (pre-null-safety) |
| Framework | Flutter `~1.x` |
| Local DB | `sqflite ^1.3.0` |
| Charts | `charts_flutter ^0.9.0` (Google – now abandoned) |
| Navigation | Named routes (`MaterialApp.routes`) |
| State management | `StatefulWidget` (no external library) |

---

## Directory Structure (current)

```
lib/
├── main.dart                          # App entry point, route table
├── app/
│   └── column_labels.dart             # Global SQLite column name constants
├── db_handler/
│   ├── handlers/
│   │   └── db_handler.dart            # Singleton DB access class
│   └── models/
│       ├── expense_model.dart          # Expense domain model
│       ├── category_cost_sums_model.dart
│       └── item_cost_sums_model.dart
├── pages/
│   ├── home_page.dart                 # Analytics home (StatefulWidget)
│   ├── form_page.dart                 # Add-expense dialog/page
│   └── history_page.dart              # Expense history list (stub)
test/
├── widget_test.dart
└── db_handler/
    ├── db_handler_test.dart
    └── models/
android/
iOS/
```

---

## Architectural Patterns (current)

### Data Layer
- `DBHandler` is a **singleton** that wraps `sqflite`.
- It exposes async helper methods: `insert`, `getAll`, `getExpensesBetweenDates`, `getTopNumCosts`, `getCategoryCostSums`, `getItemCostSums`, `getTotalCostSince`, `getTotalCostBetween`.
- Column name constants are centralised in `column_labels.dart`.
- Three query result models exist: `Expense`, `CategoryCostSum`, `ItemCostSum`.

### Presentation Layer
- **No state management library** – state is managed via `setState` inside `StatefulWidget`s.
- Widgets call `DBHandler.handler` directly (tightly coupled to data layer).
- Charts use `FutureBuilder` to fetch data on render.
- Navigation uses named routes defined in `main.dart`.

### Known Issues / Tech Debt (pre-modernisation)
- `charts_flutter` is abandoned; needs replacement.
- Deprecated Material widgets in use: `FlatButton`, `RaisedButton`.
- No null safety (`dart >=2.1.0`).
- `print()` calls left in production code.
- `// TODO: implement build` comments not cleaned up.
- Direct DB access in widget layer violates separation of concerns.
- No dependency injection; singleton makes unit testing harder.
- No linting configuration (`analysis_options.yaml` absent).
- Android Gradle configuration uses deprecated `jcenter()` repository.
- Kotlin version `1.3.50` and AGP `3.5.0` are far out of date.

---

## Target Architecture Direction

> Full proposals in `ai/tickets/SAI-0001/analysis/`.

- **Dart 3 / Flutter 3.x** with null safety enabled.
- **Feature-based folder structure** inside `lib/`.
- **Repository pattern** to decouple data access from UI.
- **Riverpod or Bloc** for state management (to be decided in analysis phase).
- **Replacement chart library** (e.g., `fl_chart`).
- **Proper linting** via `flutter_lints`.
- **CI/CD** with GitHub Actions: test, build APK, publish releases.
