# Research: Modern Flutter Best Practices

> Research scope: Error handling patterns, logging, app flavors/environments, accessibility, localization, performance, code generation tools, Flutter DevTools.

---

## 1. Error Handling Patterns

### The Problem with Raw Exceptions

Dart exceptions are invisible in function signatures — `Future<List<Expense>>` could throw at runtime with no compile-time hint to callers.

### Option A: Sealed Result Type (Recommended, No Package Required)

Dart 3's sealed classes + exhaustive pattern matching make a custom `Result<T>` type ergonomic:

```dart
// lib/core/result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? exception;
  const Failure(this.message, {this.exception});
}
```

Usage with Dart 3 pattern matching:

```dart
// Repository method
Future<Result<List<Expense>>> getAll() async {
  try {
    final rows = await _db.query(tableExpenses);
    return Success(rows.map(Expense.fromMap).toList());
  } catch (e) {
    return Failure('Failed to load expenses', exception: e);
  }
}

// Call site — exhaustive at compile time
final result = await repository.getAll();
switch (result) {
  case Success(:final data): renderExpenses(data);
  case Failure(:final message): showError(message);
}
```

**Source:** https://dart.dev/language/patterns

### Option B: fpdart (Functional Programming)

For teams comfortable with FP, `fpdart` provides `TaskEither<L, R>` — an async operation that may fail, composable with `flatMap`/`map`:

```dart
// https://pub.dev/packages/fpdart
import 'package:fpdart/fpdart.dart';

// Repository interface
abstract interface class ExpenseRepository {
  TaskEither<Failure, List<Expense>> getAll();
  TaskEither<Failure, Unit> insert(Expense expense);
}

// Usage
final result = await repository.getAll().run();
result.fold(
  (failure) => showError(failure.message),
  (expenses) => renderExpenses(expenses),
);
```

**Source:** https://pub.dev/packages/fpdart

### Option C: result_dart (Lightweight)

```dart
// https://pub.dev/packages/result_dart
Future<Result<List<Expense>>> getAll() async =>
    Result.tryCatch(
      () async => await _queryAll(),
      (error, _) => Failure(error.toString()),
    );
```

**Recommendation:** Use the custom `sealed class Result<T>` (Option A) — no extra dependency, fully exhaustive with Dart 3. Adopt `fpdart` if the team wants full FP composition.

### Error Hierarchy

Define a sealed `Failure` class hierarchy for domain-specific errors:

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
```

---

## 2. Logging

### Option A: `logger` Package (Recommended)

```dart
// https://pub.dev/packages/logger
import 'package:logger/logger.dart';

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  filter: DevelopmentFilter(), // Silent in release builds automatically
);

// Usage
log.d('Loading expenses from DB');
log.i('Loaded ${expenses.length} expenses');
log.w('Expense count exceeds threshold');
log.e('DB write failed', error: e, stackTrace: st);
```

`DevelopmentFilter` ensures no logs appear in release builds — zero production overhead.

**Source:** https://pub.dev/packages/logger

### Option B: `dart:developer` (Built-in, DevTools Integration)

```dart
import 'dart:developer' as dev;

dev.log('Loading expenses', name: 'ExpenseRepo', level: 800);
dev.log('DB error', name: 'DB', error: e, stackTrace: st, level: 1000);
```

Logs appear in Flutter DevTools → Logging tab with structured metadata. Zero dependencies.

### Recommendation

Use `logger` with `PrettyPrinter` for readable console output during development. For release builds, the `DevelopmentFilter` handles silencing automatically. Both can coexist: route `logger` output through a custom `LogOutput` that calls `dart:developer.log()` internally.

Replace all `print()` calls — they appear in release builds and have no level filtering.

---

## 3. App Flavors / Environments

Even for a local-only app, two environments (`dev` and `prod`) prevent running debug settings in production.

### Flutter Flavor Setup

Official docs: https://docs.flutter.dev/deployment/flavors

```dart
// lib/core/config/app_config.dart
enum Flavor { dev, prod }

class AppConfig {
  static late Flavor flavor;

  static void initialize(Flavor f) => flavor = f;

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;
}

// lib/main_dev.dart
void main() {
  AppConfig.initialize(Flavor.dev);
  runApp(const ExpenseTrackerApp());
}

// lib/main_prod.dart
void main() {
  AppConfig.initialize(Flavor.prod);
  runApp(const ExpenseTrackerApp());
}
```

Run commands:
```bash
flutter run -t lib/main_dev.dart
flutter build apk -t lib/main_prod.dart
```

### `--dart-define-from-file` (Lightweight Alternative)

For environment-specific values without separate app IDs (sufficient for a local-only app):

```json
// config/dev.json
{ "FLAVOR": "dev", "SHOW_DEBUG_BANNER": "true" }
```

```bash
flutter run --dart-define-from-file=config/dev.json
```

```dart
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
const showDebugBanner = bool.fromEnvironment('SHOW_DEBUG_BANNER', defaultValue: false);
```

### `envied` for Secrets

For any configuration values that should not appear in source code:

```dart
// https://pub.dev/packages/envied
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'API_KEY', obfuscate: true)
  static final String apiKey = _Env.apiKey;
}
```

**Source:** https://pub.dev/packages/envied

---

## 4. Accessibility

### Flutter Semantics API

Most Material widgets handle semantics automatically. Explicit `Semantics` annotation is needed for:
- Custom gesture detectors without inherent semantics
- Icon-only buttons (no text label)
- Decorative images
- Complex custom-painted widgets

```dart
// Icon-only button
Semantics(
  label: 'Delete expense',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: onDelete,
  ),
)

// Decorative image
ExcludeSemantics(
  child: Image.asset('assets/decorative_banner.png'),
)

// Compound list tile — merge into single announcement
MergeSemantics(
  child: ListTile(
    title: Text(expense.item),
    subtitle: Text('\$${expense.cost}'),
  ),
)
```

### `accessibility_tools` Package

Shows runtime warnings for common accessibility issues during development:

```dart
// https://pub.dev/packages/accessibility_tools
MaterialApp(
  builder: (context, child) => AccessibilityTools(child: child),
  // ...
)
```

Checks:
- Missing semantic labels on interactive widgets
- Tap targets below 48×48dp (Material) / 44×44pt (iOS)
- Font overflow under large text scaling
- Missing image semantic labels

Compiles out of release builds automatically (uses `kDebugMode`).

**Source:** https://pub.dev/packages/accessibility_tools

### Minimum Tap Target

Material Design 3 requires 48×48dp minimum. `IconButton` and `ElevatedButton` enforce this by default. For custom widgets:

```dart
GestureDetector(
  onTap: onTap,
  child: const SizedBox(
    width: 48,
    height: 48,
    child: Center(child: Icon(Icons.star, size: 24)),
  ),
)
```

### Testing Accessibility in Flutter Tests

```dart
testWidgets('delete button has correct semantics', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(myWidget);

  expect(
    tester.getSemantics(find.byType(IconButton)),
    matchesSemantics(label: 'Delete expense', isButton: true),
  );

  handle.dispose();
});
```

**Source:** https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility

---

## 5. Localization (l10n)

Even for a single-language English app, using Flutter's l10n infrastructure is recommended:
1. All user-facing strings in one place (easy to audit, A/B test)
2. Correct date/number/currency formatting for the device locale
3. Adding a second language later requires zero code refactoring
4. Better screen reader support with properly formed strings

### Setup

```yaml
# pubspec.yaml
flutter:
  generate: true  # enables flutter gen-l10n
```

```yaml
# l10n.yaml (project root)
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Expense Tracker",
  "addExpense": "Add Expense",
  "deleteExpense": "Delete expense",
  "noExpenses": "No expenses yet",
  "expenseCount": "{count, plural, =0{No expenses} =1{1 expense} other{{count} expenses}}",
  "@expenseCount": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```

Access in widgets:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.addExpense)
```

### Date and Currency Formatting

```dart
import 'package:intl/intl.dart';

// Formats correctly for device locale (e.g., $42.00 vs €42,00)
final currency = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');
currency.format(42.0); // → "$42.00"

final date = DateFormat.yMMMMd();
date.format(DateTime.now()); // → "March 24, 2026"
```

**Source:** https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
**Source:** https://pub.dev/packages/intl

---

## 6. Performance Best Practices

### `const` Widgets (Highest Impact, Zero Cost)

`const` widgets are canonicalized at compile time — Flutter skips `build()` entirely for them during parent rebuilds.

```dart
// Prefer this
const Text('Expenses')
const SizedBox(height: 16)
const Icon(Icons.add)

// Over this — allocates a new instance every rebuild
Text('Expenses')
```

Enable the lint rule `prefer_const_constructors` in `analysis_options.yaml` — the analyzer will warn when `const` could be used but isn't.

### `RepaintBoundary` for Isolated Animation

```dart
RepaintBoundary(
  child: AnimatedExpenseChart(data: data),
)
```

Isolates the animated subtree in its own compositing layer. Use Flutter DevTools → Widget Inspector → "Highlight Repaints" to identify candidates.

**Source:** https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html

### `ListView.builder` for All Lists

```dart
// Always use .builder for lists with more than ~10 items
ListView.builder(
  itemCount: expenses.length,
  itemBuilder: (context, index) => ExpenseTile(expense: expenses[index]),
)
```

### Minimal `setState` Scope

Call `setState` on the smallest widget possible. Calling it on a large parent rebuilds the entire subtree. Use state management (Riverpod/Bloc) with granular selectors to rebuild only affected widgets.

### Image Optimization

```dart
// Decode at display size, not original size
Image.asset(
  'assets/images/banner.png',
  cacheWidth: 400,
  cacheHeight: 200,
)
```

### `compute()` for Heavy Work

```dart
// Off the main thread
final sorted = await compute(sortExpenses, expenses);
final parsed = await Isolate.run(() => parseCSVData(rawString));
```

### Always Profile in Profile/Release Mode

```bash
flutter run --profile  # removes debug overhead, keeps DevTools
```

**Source:** https://docs.flutter.dev/perf/best-practices

---

## 7. Code Generation Tools

### `build_runner` (Foundation)

```bash
# Single build
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

**Source:** https://pub.dev/packages/build_runner

### `freezed` (Immutable Data Classes + Sealed States)

Generates `toString`, `==`, `hashCode`, `copyWith`, and union type pattern matching:

```dart
// https://pub.dev/packages/freezed
@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String item,
    required String category,
    required double cost,
    required DateTime date,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}

// State unions
@freezed
sealed class ExpenseState with _$ExpenseState {
  const factory ExpenseState.initial() = _Initial;
  const factory ExpenseState.loading() = _Loading;
  const factory ExpenseState.loaded(List<Expense> expenses) = _Loaded;
  const factory ExpenseState.error(String message) = _Error;
}
```

Dart 3 pattern matching on sealed states:
```dart
switch (state) {
  case ExpenseState.loaded(:final expenses) => ExpenseList(expenses: expenses),
  case ExpenseState.loading() => const CircularProgressIndicator(),
  case ExpenseState.error(:final message) => Text(message),
  case ExpenseState.initial() => const SizedBox.shrink(),
}
```

**Source:** https://pub.dev/packages/freezed

### `json_serializable` (JSON Marshaling)

```dart
// https://pub.dev/packages/json_serializable
@JsonSerializable()
class ExpenseDto {
  @JsonKey(name: 'amount_cents')
  final int amountCents;

  const ExpenseDto({required this.amountCents});

  factory ExpenseDto.fromJson(Map<String, dynamic> json) => _$ExpenseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseDtoToJson(this);
}
```

**Source:** https://pub.dev/packages/json_serializable

### `flutter_gen` (Type-Safe Assets)

```yaml
# pubspec.yaml dev_dependencies: flutter_gen_runner: ^5.x.x
# flutter_gen: assets:
#   enabled: true
```

```dart
// Before
Image.asset('assets/images/logo.png')  // runtime crash if path is wrong

// After — compile-time error if asset doesn't exist
Assets.images.logo.image()
```

**Source:** https://pub.dev/packages/flutter_gen

---

## 8. Flutter DevTools

**Access:** `dart devtools` in terminal, or from VS Code (Command Palette → "Open DevTools") or Android Studio (View → Tool Windows → Flutter Inspector)

### Key Panels

| Panel | What to Use It For |
|---|---|
| **Widget Inspector** | Debug layout issues; toggle "Highlight Repaints"; view Semantics tree |
| **Performance** | Find janky frames (>16ms); flame chart for slow `build()`/`paint()` calls |
| **CPU Profiler** | Find expensive Dart code paths during `--profile` mode |
| **Memory** | Detect memory leaks; inspect heap allocations |
| **Network** | Inspect HTTP requests and responses |
| **Logging** | View `dart:developer` log output with filtering |
| **App Size** | Treemap of APK/IPA size by package/asset |

### "Highlight Repaints" Workflow

1. Run the app in debug mode
2. Open DevTools → Widget Inspector → toggle "Highlight Repaints"
3. Any widget with a rapidly cycling border color is repainting too often
4. Fix: add `RepaintBoundary`, reduce `setState` scope, or use `const`

### Performance Overlay in App

```dart
MaterialApp(
  showPerformanceOverlay: AppConfig.isDev,
  // ...
)
```

Two bars: UI thread (top) and Raster/GPU thread (bottom). Any bar exceeding 16ms (1 frame at 60fps) causes visible jank.

**Source:** https://docs.flutter.dev/tools/devtools/overview

---

## Sources

- https://dart.dev/language/patterns
- https://pub.dev/packages/fpdart
- https://pub.dev/packages/result_dart
- https://pub.dev/packages/logger
- https://api.dart.dev/dart-developer/log.html
- https://docs.flutter.dev/deployment/flavors
- https://pub.dev/packages/envied
- https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- https://pub.dev/packages/accessibility_tools
- https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- https://pub.dev/packages/intl
- https://docs.flutter.dev/perf/best-practices
- https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html
- https://pub.dev/packages/freezed
- https://pub.dev/packages/json_serializable
- https://pub.dev/packages/build_runner
- https://pub.dev/packages/flutter_gen
- https://docs.flutter.dev/tools/devtools/overview
