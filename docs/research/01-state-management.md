# Research: Flutter State Management

> Research scope: Riverpod 2.x, Bloc/Cubit, Provider, and GetX — comparing each for a small, local-only Flutter app.

---

## 1. Riverpod 2.x (flutter_riverpod)

**Package:** https://pub.dev/packages/flutter_riverpod
**Annotation package:** https://pub.dev/packages/riverpod_annotation
**Docs:** https://riverpod.dev

### Overview

Riverpod is a compile-safe, reactive state management library for Flutter. Version 2.x introduced code generation via `riverpod_annotation` + `build_runner`, which is now the recommended approach for new projects.

### Core Concepts

**Providers** are the fundamental unit of Riverpod. They define pieces of state or computed values that widgets can watch.

| Provider Type | Use Case |
|---|---|
| `@riverpod` (generated) | Preferred approach; auto-selects provider type based on return type |
| `Provider` | Exposes a read-only value or service |
| `StateProvider` | Simple mutable value (counter, filter selection) |
| `NotifierProvider` | Complex state with multiple methods |
| `AsyncNotifierProvider` | Async state with loading/error/data phases |
| `StreamProvider` | Wraps a `Stream` (e.g., SQLite change stream) |
| `FutureProvider` | Wraps a `Future` (e.g., initial data load) |

### Code Generation Approach (Recommended)

```dart
// lib/features/expenses/application/expense_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_notifier.g.dart';

@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<Expense>> build() async {
    return ref.watch(expenseRepositoryProvider).getAll();
  }

  Future<void> addExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).insert(expense);
    ref.invalidateSelf(); // re-run build()
  }

  Future<void> deleteExpense(int id) async {
    await ref.read(expenseRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
```

### Widget Integration

```dart
class ExpenseListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseNotifierProvider);

    return expensesAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
      data: (expenses) => ExpenseList(expenses: expenses),
    );
  }
}
```

### Key Advantages

- **Compile-time safety:** Providers are global constants; no `context` required to read them.
- **Auto-dispose:** `@riverpod` (keepAlive: false by default) disposes state when no longer watched — prevents memory leaks.
- **Dependency injection built-in:** `ref.read(repositoryProvider)` replaces manual DI setup.
- **Testability:** Override any provider in tests with `ProviderContainer(overrides: [...])` — no mocking framework needed for state.
- **DevTools extension:** Riverpod has a Flutter DevTools extension tab showing the provider graph in real time.

### Selector Pattern (Preventing Over-rebuilds)

```dart
// Only rebuilds when the expense count changes, not on every update
final count = ref.watch(expenseNotifierProvider.select((s) => s.valueOrNull?.length));
```

### Testing Pattern

```dart
test('adds expense correctly', () async {
  final container = ProviderContainer(overrides: [
    expenseRepositoryProvider.overrideWith((ref) => FakeExpenseRepository()),
  ]);

  await container.read(expenseNotifierProvider.notifier).addExpense(testExpense);
  final state = await container.read(expenseNotifierProvider.future);
  expect(state, contains(testExpense));
});
```

### Packages Required

```yaml
dependencies:
  flutter_riverpod: ^2.5.x
  riverpod_annotation: ^2.3.x

dev_dependencies:
  riverpod_generator: ^2.4.x
  build_runner: ^2.4.x
  riverpod_lint: ^2.x.x  # lint rules for Riverpod
  custom_lint: ^0.6.x     # required by riverpod_lint
```

---

## 2. Bloc / Cubit (flutter_bloc)

**Package:** https://pub.dev/packages/flutter_bloc
**Docs:** https://bloclibrary.dev

### Overview

Bloc (Business Logic Component) separates UI from business logic using a unidirectional data flow: Events → Bloc → States. Cubit is a simplified version without events.

### Cubit (Simpler)

```dart
// lib/features/expenses/cubit/expense_cubit.dart
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseCubit(this._repository) : super(const ExpenseState.initial());

  Future<void> loadExpenses() async {
    emit(const ExpenseState.loading());
    try {
      final expenses = await _repository.getAll();
      emit(ExpenseState.loaded(expenses));
    } catch (e) {
      emit(ExpenseState.error(e.toString()));
    }
  }
}
```

### Bloc (Full Events Pattern)

```dart
// Events
sealed class ExpenseEvent {}
class LoadExpenses extends ExpenseEvent {}
class AddExpense extends ExpenseEvent { final Expense expense; AddExpense(this.expense); }
class DeleteExpense extends ExpenseEvent { final int id; DeleteExpense(this.id); }

// Bloc
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(const ExpenseState.initial()) {
    on<LoadExpenses>(_onLoad);
    on<AddExpense>(_onAdd);
    on<DeleteExpense>(_onDelete);
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(const ExpenseState.loading());
    try {
      final expenses = await _repository.getAll();
      emit(ExpenseState.loaded(expenses));
    } catch (e) {
      emit(ExpenseState.error(e.toString()));
    }
  }
  // ...
}
```

### Widget Integration

```dart
BlocProvider(
  create: (context) => ExpenseCubit(context.read<ExpenseRepository>())..loadExpenses(),
  child: BlocBuilder<ExpenseCubit, ExpenseState>(
    builder: (context, state) => switch (state) {
      ExpenseStateInitial() => const SizedBox.shrink(),
      ExpenseStateLoading() => const CircularProgressIndicator(),
      ExpenseStateLoaded(:final expenses) => ExpenseList(expenses: expenses),
      ExpenseStateError(:final message) => Text(message),
    },
  ),
)
```

### Key Advantages

- Explicit, auditable state transitions (every state change is a new immutable object).
- Works naturally with `freezed` for sealed state classes.
- `flutter_bloc` DevTools extension shows event/state streams in real time.
- Large community, well-documented patterns, many open-source examples.

### Key Disadvantages

- More boilerplate than Riverpod (especially full Bloc vs Cubit).
- Manual dependency injection required (use `get_it` + `injectable`, or `RepositoryProvider`).
- No auto-dispose — memory management is more explicit.

### Testing Pattern

```dart
blocTest<ExpenseCubit, ExpenseState>(
  'loads expenses',
  build: () => ExpenseCubit(mockRepository),
  setUp: () => when(() => mockRepository.getAll()).thenAnswer((_) async => [testExpense]),
  act: (cubit) => cubit.loadExpenses(),
  expect: () => [
    const ExpenseState.loading(),
    ExpenseState.loaded([testExpense]),
  ],
);
```

---

## 3. Provider (provider package)

**Package:** https://pub.dev/packages/provider

### Overview

Provider wraps `InheritedWidget` with a simpler API. It was the official recommended solution before Riverpod (from the same author, Remi Rousselet).

### Current Status (2024-2025)

Provider remains widely used and fully supported, but the Flutter and Dart community has largely moved to Riverpod for new projects. Key limitations:

- Requires `BuildContext` to access providers (limits testability).
- No `auto-dispose` equivalent.
- `ChangeNotifier` is mutable, making state harder to trace.
- No compile-time safety (type errors at runtime instead of compile time).

### Usage Pattern

```dart
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  List<Expense> _expenses = [];

  ExpenseProvider(this._repository);

  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> loadExpenses() async {
    _expenses = await _repository.getAll();
    notifyListeners();
  }
}

// Widget
Consumer<ExpenseProvider>(
  builder: (context, provider, child) => ExpenseList(expenses: provider.expenses),
)
```

### Verdict

Provider is acceptable for very simple apps or for migrating legacy code incrementally. For a new project or modernization effort, **Riverpod is the clear upgrade path** (same conceptual model, better safety and testability).

---

## 4. GetX

**Package:** https://pub.dev/packages/get

### Overview

GetX is an all-in-one Flutter framework covering state management, navigation, dependency injection, and utilities. It uses `Rx` observables and `.obs` getters.

```dart
class ExpenseController extends GetxController {
  final expenses = <Expense>[].obs;

  @override
  void onInit() {
    loadExpenses();
    super.onInit();
  }

  Future<void> loadExpenses() async {
    expenses.value = await repository.getAll();
  }
}

// Widget
Obx(() => ExpenseList(expenses: Get.find<ExpenseController>().expenses))
```

### Key Issues (Why GetX is Not Recommended for New Projects)

1. **Bypasses Flutter's widget tree:** `Get.find<T>()` doesn't use `InheritedWidget`/`BuildContext` — makes widget testing harder.
2. **Minimal type safety:** No compile-time checks on controller registration.
3. **Maintenance concerns:** GetX has had periods of slow maintenance and breaking changes.
4. **Monolithic:** Brings routing, DI, and state into one package — hard to replace individual parts.
5. **Testing difficulty:** Integration with Flutter DevTools is limited; hard to inspect state.

### Verdict

**Not recommended** for new Flutter projects. GetX solves real pain points (especially navigation) but does so in ways that create long-term maintainability issues.

---

## 5. Recommendation for This Project

For a small, local-only expense tracker:

### Recommendation: **Riverpod 2.x with Code Generation**

**Rationale:**
1. **Best testability** — providers can be overridden without mocking frameworks.
2. **No BuildContext dependency** — providers are global constants, readable anywhere.
3. **Auto-dispose** — memory-safe by default; no cleanup code needed.
4. **Natural fit for async local data** — `AsyncNotifierProvider` handles loading/error/data states cleanly.
5. **Scales well** — if the app grows, Riverpod scales to complex feature architectures.
6. **Active ecosystem** — `riverpod_lint`, DevTools extension, extensive documentation.

### Secondary Choice: **Cubit (flutter_bloc)**

If the team is already familiar with Bloc, use **Cubit** (not full Bloc with events) for simplicity. Cubit with `freezed` state classes provides explicit, auditable state at low boilerplate cost.

### Avoid for New Work

- **Provider** — acceptable for migration, not for new screens.
- **GetX** — not recommended.
- **setState alone** — acceptable only for isolated, purely local UI state (e.g., form validation).

---

## Sources

- https://riverpod.dev — Riverpod official docs
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/riverpod_annotation
- https://bloclibrary.dev — Bloc official docs
- https://pub.dev/packages/flutter_bloc
- https://pub.dev/packages/provider
- https://pub.dev/packages/get
- https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/ — Andrea Bizzotto's Riverpod architecture guide
