# Modernization Roadmap: Flutter Expense Tracker

> Based on the current state audit (`01-current-state-audit.md`) and research documents (`docs/research/`).
> Target: A well-structured, maintainable, testable Flutter 3.x app using modern Dart 3 patterns.

---

## Guiding Principles

1. **Fix blockers first** — the app cannot build with a current Flutter SDK; unblock before anything else.
2. **Incremental migration** — each phase should leave the app in a working state.
3. **Don't over-engineer** — this is a small, local-only app. Adopt modern patterns proportionally.
4. **Test as you go** — write tests when introducing new components, not at the end.

---

## Phase 1: Unblock the Build (Critical / Immediate)

These issues prevent the app from building with Flutter 3.x / Dart 3.

### 1.1 Update Dart SDK Constraint

```yaml
# pubspec.yaml
environment:
  sdk: ">=3.3.0 <4.0.0"
```

**Why:** All downstream changes depend on Dart 3 features (sealed classes, patterns, null safety enforcement).

### 1.2 Replace `charts_flutter` with `fl_chart`

`charts_flutter` is abandoned. Replace with `fl_chart`:

```yaml
dependencies:
  fl_chart: ^0.69.x  # verify latest on pub.dev
```

`fl_chart` provides `PieChartData`, `PieChartSection`, `BarChartData`, and `LineChartData` with M3-compatible styling.

**Migration effort:** Medium — the API is different but the concepts (data series, colors, labels) map directly. `pie_chart_widget.dart` needs a rewrite using `fl_chart`'s `PieChart` widget.

### 1.3 Update All Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.x
  path_provider: ^2.3.x
  cupertino_icons: ^1.0.x
  fl_chart: ^0.69.x            # replaces charts_flutter
  flutter_riverpod: ^2.5.x     # state management
  freezed_annotation: ^2.4.x   # immutable models
  json_annotation: ^4.9.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.x
  freezed: ^2.4.x
  riverpod_generator: ^2.4.x
  riverpod_annotation: ^2.3.x
  riverpod_lint: ^2.x.x
  custom_lint: ^0.6.x
  mocktail: ^1.0.x
  sqflite_ffi: ^2.3.x
  flutter_lints: ^4.x.x
```

### 1.4 Add `analysis_options.yaml`

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_fields: true
    avoid_print: true
    use_super_parameters: true
    prefer_single_quotes: true
```

**Why `avoid_print`:** Enforces replacing `print()` with structured logging.

---

## Phase 2: Fix Null Safety and Model Layer

### 2.1 Migrate `Expense` to Freezed

Replace the mutable `Expense` class with an immutable `freezed` data class:

```dart
// lib/domain/models/expense.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    int? id,
    required String item,
    required String category,
    required double cost,
    required DateTime date,
  }) = _Expense;

  // DB serialization helper methods
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] as int?,
    item: map['item'] as String,
    category: map['category'] as String,
    cost: (map['cost'] as num).toDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'item': item,
    'category': category,
    'cost': cost,
    'date': date.millisecondsSinceEpoch,
  };
}
```

Benefits:
- Immutable by default (`copyWith` generated)
- `==` and `hashCode` generated (proper value equality)
- `toString` generated (useful in debugging)
- No more manual private fields and getters

### 2.2 Migrate Aggregate Models

Apply the same pattern to `CategoryCostSum` and `ItemCostSum`:

```dart
@freezed
class CategoryCostSum with _$CategoryCostSum {
  const factory CategoryCostSum({
    required String category,
    required double totalCost,
  }) = _CategoryCostSum;

  factory CategoryCostSum.fromMap(Map<String, dynamic> map) => CategoryCostSum(
    category: map['category'] as String,
    totalCost: (map['total_cost'] as num).toDouble(),
  );
}
```

---

## Phase 3: Architecture Restructuring

### 3.1 Proposed Directory Structure

```
lib/
  core/
    theme/
      app_theme.dart        # ThemeData light + dark
      app_colors.dart       # ColorScheme + custom tokens
      app_spacing.dart      # Spacing constants
      app_radius.dart       # BorderRadius constants
    errors/
      failure.dart          # Sealed Failure hierarchy
    result.dart             # Result<T> sealed type
    config/
      app_config.dart       # Flavor/environment config
  domain/
    models/
      expense.dart          # Freezed Expense model
      category_cost_sum.dart
      item_cost_sum.dart
  data/
    local/
      database.dart         # DB initialization (sqflite)
      expense_dao.dart      # SQL queries for Expense table
    repositories/
      expense_repository.dart  # Interface + implementation
  application/
    expense_notifier.dart   # Riverpod AsyncNotifier
    expense_filter_notifier.dart
  presentation/
    pages/
      home_page.dart
      history_page.dart
      form_page.dart
    widgets/
      expense_list_tile.dart
      expense_form.dart
      pie_chart_card.dart
      drawer_widget.dart
      empty_state_widget.dart
  l10n/
    app_en.arb
  main_dev.dart
  main_prod.dart
  main.dart                 # Shared ProviderScope + MaterialApp setup
```

### 3.2 Separate DB Connection from Query Logic

Extract query logic into a DAO (Data Access Object):

```dart
// lib/data/local/expense_dao.dart
class ExpenseDao {
  final Database _db;
  const ExpenseDao(this._db);

  Future<Result<List<Expense>>> getAll() async {
    try {
      final maps = await _db.query('expenses');
      return Success(maps.map(Expense.fromMap).toList());
    } catch (e) {
      return Failure('Failed to load expenses', exception: e);
    }
  }

  Future<Result<int>> insert(Expense expense) async {
    try {
      final id = await _db.insert('expenses', expense.toMap());
      return Success(id);
    } catch (e) {
      return Failure('Failed to insert expense', exception: e);
    }
  }
}
```

### 3.3 Repository Pattern

```dart
// lib/data/repositories/expense_repository.dart
abstract interface class ExpenseRepository {
  Future<Result<List<Expense>>> getAll();
  Future<Result<int>> insert(Expense expense);
  Future<Result<void>> delete(int id);
  Future<Result<List<Expense>>> getExpensesBetweenDates(DateTime from, DateTime to);
  Future<Result<List<CategoryCostSum>>> getCategoryCostSums();
}

class SqliteExpenseRepository implements ExpenseRepository {
  final ExpenseDao _dao;
  const SqliteExpenseRepository(this._dao);

  @override
  Future<Result<List<Expense>>> getAll() => _dao.getAll();
  // ...
}
```

### 3.4 Riverpod Providers

```dart
// lib/application/providers.dart
@riverpod
Database database(DatabaseRef ref) => throw UnimplementedError(); // overridden at startup

@riverpod
ExpenseDao expenseDao(ExpenseDaoRef ref) =>
    ExpenseDao(ref.watch(databaseProvider));

@riverpod
ExpenseRepository expenseRepository(ExpenseRepositoryRef ref) =>
    SqliteExpenseRepository(ref.watch(expenseDaoProvider));

@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<Expense>> build() =>
      ref.watch(expenseRepositoryProvider).getAll().then(
        (result) => switch (result) {
          Success(:final data) => data,
          Failure(:final message) => throw Exception(message),
        },
      );

  Future<void> addExpense(Expense expense) async {
    final result = await ref.read(expenseRepositoryProvider).insert(expense);
    if (result is Failure) return; // handle error
    ref.invalidateSelf();
  }
}
```

---

## Phase 4: UI Modernization

### 4.1 Material Design 3 Theme

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static const _seedColor = Color(0xFF1B6CA8);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    textTheme: _buildTextTheme(),
    cardTheme: _buildCardTheme(),
    navigationBarTheme: _buildNavigationBarTheme(),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(),
    cardTheme: _buildCardTheme(),
  );
}
```

### 4.2 Replace Navigation Pattern

Replace string-based named routes with `go_router` for type-safe navigation:

```yaml
dependencies:
  go_router: ^14.x.x
```

```dart
final router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const HomePage()),
  GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
  GoRoute(path: '/add', builder: (_, __) => const AddExpensePage()),
]);
```

### 4.3 Replace `charts_flutter` Pie Chart

```dart
// lib/presentation/widgets/pie_chart_card.dart
import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategoryCostSum> data;
  const CategoryPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      // ...
    ];

    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) => PieChartSectionData(
          value: entry.value.totalCost,
          title: entry.value.category,
          color: colors[entry.key % colors.length],
        )).toList(),
      ),
    );
  }
}
```

### 4.4 Update Navigation UI

Replace the `Drawer` with M3 `NavigationDrawer` or `NavigationBar` (bottom nav):

```dart
Scaffold(
  body: /* screen content */,
  bottomNavigationBar: NavigationBar(
    selectedIndex: _selectedIndex,
    onDestinationSelected: (i) => setState(() => _selectedIndex = i),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.history), label: 'History'),
    ],
  ),
)
```

### 4.5 Add `const` Constructors

Apply `const` to every widget constructor and instantiation that can support it. Enable `prefer_const_constructors` lint (see Phase 1.4) to catch remaining instances automatically.

---

## Phase 5: Testing Infrastructure

### 5.1 Set Up Test Directory Structure

```
test/
  domain/
    models/
      expense_test.dart
  data/
    local/
      expense_dao_test.dart    # uses sqflite_ffi + in-memory DB
  application/
    expense_notifier_test.dart # uses ProviderContainer + mock repo
  presentation/
    widgets/
      expense_list_tile_test.dart
      expense_form_test.dart
integration_test/
  app_test.dart
```

### 5.2 Model Tests (First Priority)

```dart
// test/domain/models/expense_test.dart
void main() {
  group('Expense', () {
    test('toMap/fromMap round-trip', () {
      final expense = Expense(
        item: 'Coffee',
        category: 'Food',
        cost: 4.50,
        date: DateTime(2024, 3, 1),
      );
      expect(Expense.fromMap(expense.toMap()), equals(expense));
    });

    test('copyWith preserves unchanged fields', () {
      final original = Expense(item: 'Tea', category: 'Food', cost: 2.0, date: DateTime(2024));
      final modified = original.copyWith(cost: 3.0);
      expect(modified.item, 'Tea');
      expect(modified.cost, 3.0);
    });
  });
}
```

### 5.3 Repository/DAO Tests with sqflite_ffi

```dart
// test/data/local/expense_dao_test.dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});

test('inserts and retrieves expenses', () async {
  final db = await databaseFactory.openDatabase(inMemoryDatabasePath, ...);
  final dao = ExpenseDao(db);

  await dao.insert(Expense(item: 'Lunch', category: 'Food', cost: 12.0, date: DateTime.now()));
  final result = await dao.getAll();

  expect(result, isA<Success<List<Expense>>>());
  expect((result as Success).data.length, 1);
});
```

### 5.4 Notifier Tests with Riverpod ProviderContainer

```dart
// test/application/expense_notifier_test.dart
test('loads expenses', () async {
  final mockRepo = MockExpenseRepository();
  when(() => mockRepo.getAll()).thenAnswer((_) async => Success([testExpense]));

  final container = ProviderContainer(overrides: [
    expenseRepositoryProvider.overrideWithValue(mockRepo),
  ]);
  addTearDown(container.dispose);

  final expenses = await container.read(expenseNotifierProvider.future);
  expect(expenses, [testExpense]);
});
```

---

## Phase 6: CI/CD Pipeline

See `docs/analysis/03-ci-cd-proposal.md` for the full GitHub Actions implementation plan.

Summary:
- CI: format check + analyze + test with coverage (runs on every PR and push to main)
- Release: `release-please` for automated CHANGELOG and version bumps
- Build artifact: APK uploaded to GitHub Release on each tag
- Branch protection: require CI status checks before merging to main

---

## Phase 7: Nice-to-Have (Post-Stabilization)

These are improvements with good long-term value but are not blockers:

| Item | Package | Value |
|---|---|---|
| Localization | `intl` + ARB | Centralizes strings; date/currency formatting |
| Accessibility | `accessibility_tools` | Catch issues in dev; better screen reader support |
| Component catalog | `widgetbook` | Develop widgets in isolation |
| Type-safe assets | `flutter_gen` | Compile-time asset safety |
| Dynamic color | `dynamic_color` | Material You on Android 12+ |
| App flavors | Multiple entry points | Separate debug and release configurations |

---

## Priority Matrix

| Phase | Priority | Effort | Outcome |
|---|---|---|---|
| 1: Unblock build | P0 | Low-Medium | App builds with Flutter 3.x |
| 2: Fix models | P1 | Low | Type-safe, immutable data classes |
| 3: Architecture | P1 | Medium | Testable repository pattern + Riverpod |
| 4: UI modernization | P2 | Medium | M3 theme, go_router, fl_chart |
| 5: Testing | P2 | Medium | 80%+ coverage, CI-ready test suite |
| 6: CI/CD | P2 | Low | Automated quality gates and releases |
| 7: Nice-to-have | P3 | Low-Medium | Long-term maintainability improvements |

---

## Estimated Scope

| Phase | Files to Create/Modify | Estimated Changes |
|---|---|---|
| Phase 1 | `pubspec.yaml`, `analysis_options.yaml` | Small (config only) |
| Phase 2 | 3 model files | Small (mechanical rewrite) |
| Phase 3 | ~8 new files | Medium (new layer structure) |
| Phase 4 | ~6 modified UI files | Medium (widget updates) |
| Phase 5 | ~8 new test files | Medium |
| Phase 6 | 2-3 GitHub Actions workflows | Small |
| Phase 7 | Various | Ongoing |
