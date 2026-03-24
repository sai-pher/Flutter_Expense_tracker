# Research: Modern Flutter Testing Practices

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** Unit testing, widget testing, integration testing, mocking, SQLite testing, coverage  
> **Sources:** flutter.dev, pub.dev, GitHub repositories

---

## 1. Testing Pyramid for Flutter

Flutter supports three levels of tests, following the standard testing pyramid:

| Level | Package | Speed | Scope | Run on CI |
|-------|---------|-------|-------|-----------|
| **Unit** | `flutter_test` / `test` | Fastest | Pure Dart logic, no UI | Yes |
| **Widget** | `flutter_test` | Fast | Widget rendering, user interaction | Yes |
| **Integration** | `integration_test` | Slow | Full app on real device/emulator | Optional |

---

## 2. Unit Testing

Unit tests cover pure Dart logic with no Flutter framework or platform dependencies.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/db_handler/models/expense_model.dart';

void main() {
  group('Expense model', () {
    late Expense expense;

    setUp(() {
      expense = Expense('Coffee', 'Food', 4.50, DateTime(2024, 1, 15));
    });

    test('toMap() / fromMap() round-trip preserves all fields', () {
      final map = expense.toMap();
      final restored = Expense.fromMap({...map, '_id': 1});
      expect(restored.item, equals('Coffee'));
      expect(restored.category, equals('Food'));
      expect(restored.cost, equals(4.50));
    });

    test('dateMilli setter restores correct DateTime', () {
      final milli = expense.dateMilli;
      expense.dateMilli = milli;
      expect(expense.date, equals(DateTime(2024, 1, 15)));
    });

    test('equality compares by value not reference', () {
      final copy = Expense('Coffee', 'Food', 4.50, DateTime(2024, 1, 15));
      expect(expense, equals(copy));
    });
  });
}
```

**Key conventions:**
- One `group()` per class or module
- `setUp()` / `tearDown()` for shared fixtures
- `setUpAll()` / `tearDownAll()` for expensive one-time setup (e.g., database)
- Tests must be deterministic and side-effect-free

**Run:**
```bash
flutter test test/unit/
```

---

## 3. Widget Testing

Widget tests render widgets in a test environment without a physical device.

### Key `WidgetTester` API

| Method | Purpose |
|--------|---------|
| `tester.pumpWidget(widget)` | Mount widget tree |
| `tester.pump()` | Advance one frame |
| `tester.pump(Duration(seconds: 1))` | Advance by duration |
| `tester.pumpAndSettle()` | Pump until no pending frames (animations, async) |
| `tester.tap(finder)` | Simulate tap |
| `tester.enterText(finder, 'text')` | Keyboard input |
| `tester.drag(finder, offset)` | Drag gesture |
| `tester.ensureVisible(finder)` | Scroll to widget |

### Finder Constructors

```dart
find.text('Add Expense')           // by text
find.byType(ElevatedButton)        // by widget type
find.byKey(Key('submit-btn'))      // by Key (most stable)
find.byIcon(Icons.add)             // by icon
find.descendant(of: ..., matching: ...) // scoped
```

### Common Matchers

```dart
expect(finder, findsOneWidget);
expect(finder, findsNothing);
expect(finder, findsNWidgets(3));
expect(finder, findsWidgets);      // at least one
```

### Example: Form Widget Test

```dart
testWidgets('form submits and closes dialog', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: FormLayout())),
  );

  await tester.enterText(find.byKey(Key('item-field')), 'Lunch');
  await tester.enterText(find.byKey(Key('cost-field')), '12.50');
  await tester.tap(find.byKey(Key('submit-btn')));
  await tester.pumpAndSettle();

  // Verify the form has been dismissed
  expect(find.byType(FormLayout), findsNothing);
});
```

### Best Practices

- Assign `Key` values to interactive widgets for stable, refactoring-resistant finders
- Use `pumpAndSettle()` after actions that trigger animations or async rebuilds
- Use `pump()` (single frame) for precise animation state testing
- Wrap widget under test in `MaterialApp` for `Scaffold`, `Navigator`, `MediaQuery` context
- For widgets using state management, wrap with the provider in `pumpWidget`

**Source:** https://docs.flutter.dev/testing/overview#widget-tests  
**Source:** https://raw.githubusercontent.com/flutter/samples/main/testing_app/test/favorites_test.dart

---

## 4. Integration Testing

The `flutter_driver`-based approach is **deprecated**. The current standard is `integration_test` (bundled in the Flutter SDK since Flutter 2.0).

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add expense end-to-end', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('item-field')), 'Coffee');
    await tester.tap(find.byKey(Key('submit-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
  });
}
```

**Run:**
```bash
# On connected device:
flutter test integration_test/app_test.dart

# Legacy driver approach:
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

| Aspect | `flutter_driver` (legacy) | `integration_test` (current) |
|--------|--------------------------|-------------------------------|
| Status | Deprecated | Active, recommended |
| API | `FlutterDriver`, `SerializableFinder` | `WidgetTester` (same as widget tests) |
| Process | Separate from app | Same process |
| Platforms | Android, iOS | Android, iOS, web, desktop |

**Source:** https://pub.dev/packages/integration_test  
**Source:** https://docs.flutter.dev/testing/integration-tests

---

## 5. Mocking: mocktail vs mockito

| Feature | mocktail | mockito |
|---------|----------|---------|
| Code generation | Not required | Required (`build_runner`) |
| Null safety | Native | Via code gen (5.x+) |
| Syntax | `when(() => obj.method())` | `when(obj.method())` |
| Verification | `verify(() => obj.method())` | `verify(obj.method())` |
| Maintenance | felangel (bloc author) | Dart team |

**Recommendation: `mocktail` for new projects** — no build step, simpler setup.

```dart
// mocktail example
import 'package:mocktail/mocktail.dart';

class MockDBHandler extends Mock implements DBHandler {}

void main() {
  late MockDBHandler mockDB;

  setUp(() => mockDB = MockDBHandler());

  test('getAll returns expenses from repository', () async {
    final expenses = [Expense('Coffee', 'Food', 4.5, DateTime.now())];
    when(() => mockDB.getAll()).thenAnswer((_) async => expenses);

    final result = await mockDB.getAll();

    expect(result, equals(expenses));
    verify(() => mockDB.getAll()).called(1);
  });
}
```

**Note:** For custom argument types with mocktail, call `registerFallbackValue(MyCustomClass())` in `setUpAll`.

**Source:** https://pub.dev/packages/mocktail  
**Source:** https://pub.dev/packages/mockito

---

## 6. Testing SQLite / sqflite on CI

`sqflite` uses platform channels and cannot run in standard unit tests without a device. `sqflite_common_ffi` provides an FFI-backed SQLite implementation that runs on Linux/macOS/Windows — exactly what CI needs.

```yaml
# pubspec.yaml
dev_dependencies:
  sqflite_common_ffi: ^2.4.0
```

```yaml
# GitHub Actions step (ubuntu-latest runner)
- name: Install SQLite
  run: sudo apt-get install -y libsqlite3-0 libsqlite3-dev
```

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;  // redirect global factory
  });

  test('insert and retrieve expense', () async {
    // Use in-memory DB — no filesystem, no state leakage
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    // Create schema, insert, assert...
    await db.close();
  });
}
```

### Handling the DBHandler Singleton

The current `DBHandler` singleton with a static `_database` field makes testing harder. Options:

1. **Expose `resetForTesting()`** — nulls out `_database` between tests (quick fix)
2. **Redirect `databaseFactory`** before the singleton initialises (works with `sqflite_common_ffi`)
3. **Refactor to accept injected `DatabaseFactory`** (most testable — recommended as part of architecture modernisation)

**Source:** https://pub.dev/packages/sqflite_common_ffi

---

## 7. Coverage Targets and Tooling

```bash
# Generate coverage
flutter test --coverage
# Output: coverage/lcov.info

# Remove generated files from coverage
lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' \
     -o coverage/lcov_cleaned.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

| Tool | Role |
|------|------|
| `flutter test --coverage` | Generate `lcov.info` |
| `VeryGoodOpenSource/very_good_coverage@v3` | CI threshold enforcement |
| `romeovs/lcov-reporter-action` | PR comment with coverage diff |
| `genhtml` (lcov CLI) | Local HTML report |

**Recommended coverage targets:**

| Layer | Target |
|-------|--------|
| Domain models (`Expense`, etc.) | 90–100% |
| Data layer (`DBHandler`) | 80–90% |
| UI widgets | 60–80% |
| Overall project | 75–85% |

Start with `min_coverage: 70` in CI and raise incrementally as tests are added.

**Source:** https://github.com/VeryGoodOpenSource/very_good_coverage  
**Source:** https://pub.dev/packages/coverage

---

## 8. Test Plan for This Expense Tracker

### Unit Tests (pure Dart, fast)

| Subject | Tests |
|---------|-------|
| `Expense` model | `toMap()` / `fromMap()` round-trip; `dateMilli` setter; equality; `toString()` |
| `CategoryCostSum` model | `fromMap()` parsing; field access |
| `ItemCostSum` model | `fromMap()` parsing; field access |

### DB Integration Tests (sqflite_common_ffi, in-memory)

| Subject | Tests |
|---------|-------|
| `DBHandler.insert()` | Returns valid row ID; record persists |
| `DBHandler.getAll()` | Empty list on fresh DB; all records returned |
| `DBHandler.getExpensesBetweenDates()` | Correct date-range filtering |
| `DBHandler.getTopNumCosts()` | Correct limit + sort by cost desc |
| `DBHandler.getCategoryCostSums()` | Correct aggregation per category |
| `DBHandler.getItemCostSums()` | Correct aggregation per item |
| `DBHandler.getTotalCostSince()` | Correct sum for date range |
| `DBHandler.getTotalCostBetween()` | Correct sum for bounded range |
| Schema creation | `_onCreate` creates table with correct columns |

### Widget Tests

| Subject | Tests |
|---------|-------|
| `HomePage` | Renders without error; FAB visible |
| `FormLayout` | All fields present; valid submit inserts expense |
| `PieChartWidget` | Renders loading state; renders with data |
| `DrawerWidget` | Navigation links present |

### Integration Tests (on device, optional for CI)

| Scenario |
|----------|
| App launches → add expense → appears in list |
| Navigate between Home, Form, History without crashing |

---

## Sources

| Topic | URL |
|-------|-----|
| Flutter testing overview | https://docs.flutter.dev/testing/overview |
| Widget testing | https://docs.flutter.dev/testing/overview#widget-tests |
| Integration testing | https://docs.flutter.dev/testing/integration-tests |
| `integration_test` package | https://pub.dev/packages/integration_test |
| `mocktail` | https://pub.dev/packages/mocktail |
| `mockito` | https://pub.dev/packages/mockito |
| `sqflite_common_ffi` | https://pub.dev/packages/sqflite_common_ffi |
| `coverage` package | https://pub.dev/packages/coverage |
| `VeryGoodOpenSource/very_good_coverage` | https://github.com/VeryGoodOpenSource/very_good_coverage |
| Flutter samples testing app | https://github.com/flutter/samples/tree/main/testing_app |
