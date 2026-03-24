# Research: Flutter App Architecture (Local-Only App)

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** Architecture patterns for a local SQLite-backed Flutter app; state management; DI  
> **Sources:** pub.dev, flutter.dev, bloclibrary.dev

---

## 1. The Three-Layer Model (Flutter Official)

Flutter’s official architecture guide describes three layers:

```
Presentation Layer  →  ViewModels / Notifiers / Cubits  →  Widgets / Pages
Domain Layer        →  Entities, Repository interfaces, (optional Use Cases)
Data Layer          →  Repository implementations, DataSources, Models
```

For a local-only app with no backend, the domain layer is thin — formal “use cases” or “interactors” are not needed. The key boundary is between the data layer (raw SQLite) and the presentation layer (UI state).

**Source:** https://docs.flutter.dev/app-architecture

---

## 2. Repository Pattern for SQLite

The repository pattern inserts an interface between the database and the rest of the app.

**Why it matters:**
- UI code never imports `sqflite` directly
- The repository can be replaced with an in-memory fake for tests
- Multiple datasources (e.g. SQLite + CSV import) can be merged behind one interface
- The singleton `DBHandler` pattern is removed from widget code

```dart
// lib/data/datasources/expense_datasource.dart
abstract interface class ExpenseLocalDatasource {
  Future<List<Map<String, dynamic>>> getAllExpenses();
  Future<int> insertExpense(Map<String, dynamic> data);
  Future<int> deleteExpense(int id);
}

class SqfliteExpenseDatasource implements ExpenseLocalDatasource {
  final Database _db;
  SqfliteExpenseDatasource(this._db);
  // ... sqflite calls
}
```

```dart
// lib/domain/repositories/expense_repository.dart
abstract interface class ExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<void> addExpense(Expense expense);
  Future<List<CategoryCostSum>> getCategoryCostSums();
  // ...
}
```

```dart
// lib/data/repositories/expense_repository_impl.dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDatasource _datasource;
  ExpenseRepositoryImpl(this._datasource);

  @override
  Future<List<Expense>> getAllExpenses() async {
    final maps = await _datasource.getAllExpenses();
    return maps.map(Expense.fromMap).toList();
  }
}
```

**Migration note:** The existing `DBHandler` already does most of what the datasource would do. The primary change is removing direct singleton access (`DBHandler.handler.X()`) from widgets/pages and replacing it with injected repositories.

---

## 3. State Management Options

### Provider

- The original Flutter state management package.
- Simple and familiar, but has known limitations: type-safety issues, inability to declare providers outside the widget tree.
- **Not recommended for new projects.** Riverpod was created to fix its design issues.

**Source:** https://pub.dev/packages/riverpod (describes itself as evolution of Provider)

---

### flutter_bloc / Cubit

**Cubit** (lightweight variant of BLoC):
- A class that exposes methods which call `emit(newState)`. No event classes required.
- Clear unidirectional data flow. Easy to test: call method → assert emitted states.

**Bloc** (full variant):
- Formal event system: events go in, states come out.
- Best when you need to log, replay, or transform event streams.

```dart
// Cubit example
class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpenseRepository _repository;
  ExpensesCubit(this._repository) : super(ExpensesInitial());

  Future<void> loadExpenses() async {
    emit(ExpensesLoading());
    try {
      final expenses = await _repository.getAllExpenses();
      emit(ExpensesLoaded(expenses));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }
}
```

**Verdict for this app:** Cubit is sufficient. The event overhead of full Bloc is not justified for a simple CRUD expense tracker.

**Source:** https://pub.dev/packages/flutter_bloc  
**Source:** https://pub.dev/packages/bloc

---

### Riverpod 2.x / 3.x

Riverpod replaces Provider with:
- Compile-time safety (no `ProviderNotFoundException` at runtime)
- No `BuildContext` dependency for reading providers
- Built-in async state: loading / error / data handled automatically
- Built-in DI: provider graph handles construction order

With code generation (`riverpod_annotation` + `build_runner`), the `@riverpod` annotation generates all provider boilerplate:

```dart
// lib/presentation/providers/expenses_notifier.dart
@riverpod
class ExpensesNotifier extends _$ExpensesNotifier {
  @override
  Future<List<Expense>> build() async {
    return ref.watch(expenseRepositoryProvider).getAllExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).addExpense(expense);
    ref.invalidateSelf();
  }
}
```

**Versions:** Riverpod 3.x (current stable 3.3.1 as of 2026-03) merged `AutoDisposeNotifier` into `Notifier`. Use `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`.

**Verdict for this app: Riverpod 3.x is the strongest choice.** It eliminates the need for a separate DI library, handles async database calls gracefully (loading/error states), and scales well if the app grows.

**Source:** https://pub.dev/packages/flutter_riverpod  
**Source:** https://pub.dev/packages/riverpod_annotation

---

### Comparison Summary

| Criterion | Provider | Cubit | Riverpod 3.x |
|-----------|----------|-------|--------------|
| Type safety | Weak | Strong | Strong |
| Async state (loading/error/data) | Manual | Manual (state classes) | Built-in |
| DI without BuildContext | No | Via RepositoryProvider | Yes, natively |
| Boilerplate | Low | Medium | Low (with codegen) |
| Testability | Moderate | High | High |
| Recommended for new projects | No | Yes | Yes (preferred) |

---

## 4. Dependency Injection

### Option A: Riverpod’s built-in provider graph (recommended with Riverpod)

Providers declare dependencies via `Ref`. The provider graph handles construction order and lifetime:

```dart
@riverpod
Future<Database> appDatabase(Ref ref) async {
  final path = await getDatabasesPath();
  return openDatabase(
    join(path, 'expenses.db'),
    version: 1,
    onCreate: (db, version) => db.execute('CREATE TABLE ...'),
  );
}

@riverpod
ExpenseRepository expenseRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return ExpenseRepositoryImpl(SqfliteExpenseDatasource(db));
}
```

No separate DI library needed.

### Option B: get_it (when not using Riverpod)

Pure service locator, zero Flutter dependency, O(1) lookups:

```dart
// lib/core/di/injection.dart
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final db = await _openDatabase();
  getIt.registerSingleton<Database>(db);
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(SqfliteExpenseDatasource(getIt<Database>())),
  );
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ExpenseTrackerApp());
}
```

`injectable` (pub.dev/packages/injectable) adds annotation-based code generation on top of `get_it`.

**Source:** https://pub.dev/packages/get_it  
**Source:** https://pub.dev/packages/injectable

---

## 5. SQLite Options: sqflite vs Drift

### sqflite (current — keep)

- Flutter Favorite, 2.36M downloads, direct API
- Manual `Map<String, dynamic>` ↔ domain object mapping (`toMap()`/`fromMap()` already present)
- For desktop/test support: `sqflite_common_ffi` + `sqfliteFfiInit()`
- Best for: simple schemas, familiar SQL, minimal overhead

**Source:** https://pub.dev/packages/sqflite

### Drift (formerly Moor)

- Reactive SQLite layer with code generation. Queries return `Stream`s.
- Type-safe query builder, DAO pattern built in.
- Significantly more boilerplate via `build_runner`.
- **Verdict:** Excellent for complex schemas; overkill for a single-table expense tracker.

**Source:** https://pub.dev/packages/drift

### Isar

- NoSQL, schema defined with Dart annotations, collection-based API.
- **Verdict:** Not appropriate — the existing schema is relational; SQLite aggregation queries (GROUP BY, SUM, BETWEEN) are natural.

**Source:** https://pub.dev/packages/isar

**Recommendation: Keep sqflite.** Wrap it behind the repository pattern to improve testability.

---

## 6. Model Layer: Immutability with `freezed`

The current `Expense` class uses mutable private fields with getters/setters. Modern Dart best practice favours **immutable data classes**.

**`freezed`** (Flutter Favorite, 1.82M downloads) generates:
- `copyWith` for immutable updates
- Value equality (`==` and `hashCode`)
- `toString`
- Sealed union types (for state variants)

```dart
// lib/domain/entities/expense.dart
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
}
```

For local-only apps (no JSON API), `freezed` alone (without `json_serializable`) is sufficient.

**Source:** https://pub.dev/packages/freezed

---

## 7. Recommended Architecture for This App

Given the constraints (local-only, SQLite, single entity type, simple CRUD + analytics):

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Folder structure | Layer-first | Single feature domain |
| State management | Riverpod 3.x | Best async support, built-in DI, Flutter Favorite |
| DI | Riverpod provider graph | No extra library needed |
| Database | sqflite (keep) | Already integrated; wrap in repository |
| Models | `freezed` | Immutability, copyWith, value equality |
| Linting | `flutter_lints` (min) or `very_good_analysis` | Analysis hygiene |

**Proposed `lib/` structure:**

```
lib/
├── app/
│   ├── app.dart              # MaterialApp + ProviderScope
│   └── router.dart           # go_router config
├── core/
│   ├── constants/
│   │   └── db_constants.dart  # column names, table name
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_utils.dart
├── data/
│   ├── datasources/
│   │   ├── expense_datasource.dart         # interface
│   │   └── sqflite_expense_datasource.dart # sqflite impl
│   ├── models/
│   │   └── expense_dto.dart                # toMap/fromMap
│   └── repositories/
│       └── expense_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── expense.dart                    # @freezed
│   └── repositories/
│       └── expense_repository.dart         # interface
├── presentation/
│   ├── pages/
│   │   ├── home_page.dart
│   │   ├── add_expense_page.dart
│   │   └── history_page.dart
│   ├── widgets/
│   │   ├── expense_pie_chart.dart
│   │   ├── expense_table.dart
│   │   └── app_drawer.dart
│   └── providers/
│       ├── database_provider.dart
│       ├── expense_repository_provider.dart
│       └── expenses_notifier.dart
└── main.dart                             # ProviderScope + runApp
```

**`main.dart`:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
```

---

## Sources

| Topic | URL |
|-------|-----|
| Flutter app architecture guide | https://docs.flutter.dev/app-architecture |
| `sqflite` | https://pub.dev/packages/sqflite |
| `sqflite_common_ffi` | https://pub.dev/packages/sqflite_common_ffi |
| `flutter_riverpod` | https://pub.dev/packages/flutter_riverpod |
| `riverpod_annotation` | https://pub.dev/packages/riverpod_annotation |
| `flutter_bloc` | https://pub.dev/packages/flutter_bloc |
| `bloc` | https://pub.dev/packages/bloc |
| `get_it` | https://pub.dev/packages/get_it |
| `injectable` | https://pub.dev/packages/injectable |
| `freezed` | https://pub.dev/packages/freezed |
| `drift` | https://pub.dev/packages/drift |
| `go_router` | https://pub.dev/packages/go_router |
