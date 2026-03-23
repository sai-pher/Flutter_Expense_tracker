# Research: Flutter Repository Organisation Best Practices

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** Flutter project folder structure, file naming, assets, linting  
> **Sources:** dart.dev, pub.dev, Very Good Ventures, codewithandrea.com

---

## 1. Standard Flutter Project Root Layout

The following root-level structure is fixed by the Flutter toolchain:

```
expense_tracker/
├── android/
├── ios/
├── linux/              # desktop targets (if needed)
├── macos/
├── web/
├── windows/
├── lib/                # all Dart application code
├── test/               # all Dart test code (mirrors lib/)
├── integration_test/   # integration tests
├── assets/             # images, icons, JSON data files
├── fonts/              # custom font files
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
├── README.md
├── CONTRIBUTING.md
├── CLAUDE.md
├── architecture.md
└── .github/
    ├── workflows/
    ├── PULL_REQUEST_TEMPLATE.md
    └── CODEOWNERS
```

`analysis_options.yaml` must be at the root; the Dart analyser reads it from there.

---

## 2. Two Dominant `lib/` Strategies

### A. Layer-first (horizontal slicing)

Organises code by technical concern. Best for small-to-medium apps with one or two feature domains.

```
lib/
├── app/
│   ├── app.dart            # MaterialApp, theme
│   └── router.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasources/        # raw DB/API access
│   ├── models/             # DB transfer objects (DTOs)
│   └── repositories/       # repository implementations
├── domain/
│   ├── entities/           # immutable domain objects
│   └── repositories/       # repository interfaces (abstract)
├── presentation/
│   ├── pages/              # full-screen routes
│   ├── widgets/            # reusable UI components
│   └── providers/          # Riverpod notifiers / Cubits
└── main.dart
```

### B. Feature-first (vertical slicing)

Organises code by product feature. Better when three or more independent feature domains exist.

```
lib/
├── features/
│   ├── expenses/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── analytics/
│   └── history/
├── core/
│   ├── widgets/            # shared widgets used across features
│   ├── theme/
│   └── utils/
└── main.dart
```

**Recommendation for this app:** Layer-first. The app has one primary entity (Expense) and one feature domain. Feature-first would add structure without benefit at this scale.

**Sources:** Very Good Ventures blog; Andrea Bizzotto (codewithandrea.com); BLoC library architecture docs (pub.dev/packages/flutter_bloc)

---

## 3. File and Directory Naming

Dart's [official style guide](https://dart.dev/effective-dart/style) mandates `lowercase_with_underscores` for all file and directory names.

```
expense_model.dart       ✓
expenseModel.dart        ✗
ExpenseModel.dart        ✗
```

Files should be named after the primary class they contain:

| Class | File name |
|-------|-----------|
| `Expense` | `expense.dart` |
| `ExpenseRepository` | `expense_repository.dart` |
| `ExpensesNotifier` | `expenses_notifier.dart` |
| `HomePage` | `home_page.dart` |

**Source:** https://dart.dev/effective-dart/style

---

## 4. Where Each File Type Lives

| File type | Layer-first path |
|-----------|------------------|
| Domain entity (immutable) | `lib/domain/entities/expense.dart` |
| DB DTO (mutable, map-aware) | `lib/data/models/expense_dto.dart` |
| SQLite datasource interface | `lib/data/datasources/expense_datasource.dart` |
| SQLite datasource implementation | `lib/data/datasources/sqflite_expense_datasource.dart` |
| Repository interface | `lib/domain/repositories/expense_repository.dart` |
| Repository implementation | `lib/data/repositories/expense_repository_impl.dart` |
| Riverpod providers / Notifiers | `lib/presentation/providers/` |
| Full-screen pages/routes | `lib/presentation/pages/` |
| Reusable widgets | `lib/presentation/widgets/` |
| Global constants (DB columns, etc.) | `lib/core/constants/db_constants.dart` |
| Theme / colour scheme | `lib/core/theme/app_theme.dart` |
| Date / formatting utilities | `lib/core/utils/date_utils.dart` |
| App entry + MaterialApp | `lib/app/app.dart` |
| Router config | `lib/app/router.dart` |

---

## 5. Linting: `analysis_options.yaml`

Two main options:

### `flutter_lints` (standard, included in Flutter templates)

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    always_declare_return_types: true
    prefer_const_constructors: true
    avoid_print: true
    prefer_single_quotes: true
    use_key_in_widget_constructors: true
```

**Source:** https://pub.dev/packages/flutter_lints

### `very_good_analysis` (stricter, VGV-recommended)

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

Superset of `flutter_lints` with stricter rules: always-typed parameters, no implicit dynamic, etc. Recommended for production-grade projects.

**Source:** https://pub.dev/packages/very_good_analysis

---

## 6. Assets and Fonts Declaration

```yaml
# pubspec.yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/data/        # JSON seed data, etc.

  fonts:
    - family: Poppins
      fonts:
        - asset: fonts/Poppins-Regular.ttf
        - asset: fonts/Poppins-Bold.ttf
          weight: 700
```

- Use trailing `/` on directory paths to include all files in that directory
- Subdirectories under `assets/` are **not** automatically included — each subdirectory must be declared
- Font files live under `fonts/` at the project root

---

## 7. `test/` Structure

The `test/` directory should mirror `lib/`:

```
test/
├── data/
│   ├── datasources/
│   │   └── sqflite_expense_datasource_test.dart
│   └── repositories/
│       └── expense_repository_impl_test.dart
├── domain/
│   └── entities/
│       └── expense_test.dart
├── presentation/
│   ├── pages/
│   └── widgets/
└── helpers/                # shared test utilities, fakes, fixtures
```

---

## Sources

| Topic | URL |
|-------|-----|
| Dart effective style | https://dart.dev/effective-dart/style |
| `flutter_lints` | https://pub.dev/packages/flutter_lints |
| `very_good_analysis` | https://pub.dev/packages/very_good_analysis |
| BLoC architecture guide | https://pub.dev/packages/flutter_bloc |
| Riverpod | https://pub.dev/packages/flutter_riverpod |
| `go_router` | https://pub.dev/packages/go_router |
| `melos` (monorepo tool) | https://pub.dev/packages/melos |
