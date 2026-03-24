# Research: Flutter CI/CD with GitHub Actions and Testing Practices

> Research scope: GitHub Actions workflows, APK versioning, release automation, branch protection, coverage reporting, unit/widget/integration testing patterns.

---

## Part A: CI/CD with GitHub Actions

### 1. Core CI Workflow

The `subosito/flutter-action` marketplace action installs the Flutter SDK in GitHub Actions.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
          cache: true           # Caches Flutter SDK and pub cache

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: coverage/lcov.info
```

**Source:** https://github.com/subosito/flutter-action

### 2. APK Versioning

Flutter's `pubspec.yaml` carries the version as `1.2.3+45` where `1.2.3` is the semver marketing version and `45` is the integer build code (`versionCode` on Android).

Inject version at build time from Git tags:

```yaml
- name: Build APK
  run: |
    flutter build apk --release \
      --build-name=${GITHUB_REF_NAME#v} \
      --build-number=${{ github.run_number }}
```

- `--build-name` sets the semver version string (e.g., `1.2.3`)
- `--build-number` sets the integer build code; `github.run_number` is monotonically increasing

### 3. Release Automation: release-please

`release-please` is the recommended tool for Flutter projects. It reads conventional commits, opens a "Release PR" that bumps `pubspec.yaml` and generates `CHANGELOG.md`, then creates a GitHub Release when that PR is merged.

```yaml
# .github/workflows/release-please.yml
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: dart
          token: ${{ secrets.GITHUB_TOKEN }}
```

The `dart` release type updates the `version:` field in `pubspec.yaml` correctly.

**Source:** https://github.com/googleapis/release-please-action

### 4. Build Artifact Upload (GitHub Release)

```yaml
# .github/workflows/release.yml — triggered by release-please tags
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
          cache: true

      - name: Build APK
        run: |
          flutter build apk --release \
            --build-name=${GITHUB_REF_NAME#v} \
            --build-number=${{ github.run_number }}

      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
            build/app/outputs/flutter-apk/expense-tracker-${{ github.ref_name }}.apk

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: build/app/outputs/flutter-apk/expense-tracker-${{ github.ref_name }}.apk
          generate_release_notes: true
```

**Source:** https://github.com/softprops/action-gh-release

### 5. Conventional Commits for release-please

release-please reads conventional commit messages to determine version bumps:

| Prefix | Effect |
|---|---|
| `feat:` | Minor version bump (0.X.0) |
| `fix:` | Patch version bump (0.0.X) |
| `feat!:` or `BREAKING CHANGE:` footer | Major version bump (X.0.0) |
| `chore:`, `docs:`, `refactor:`, `test:` | No release |

Example commits:
```
feat: add category filter to expense list
fix: correct date formatting for non-US locales
feat!: replace SQLite schema with drift (breaking migration)
chore: update dependencies to latest versions
```

**Source:** https://www.conventionalcommits.org/en/v1.0.0/

### 6. APK Signing with GitHub Secrets

Store the Android keystore as a base64-encoded secret.

**Encode locally:**
```bash
base64 -w 0 my-release-key.jks > keystore_base64.txt
```

**Add GitHub Secrets** (Settings → Secrets and variables → Actions):
- `KEYSTORE_BASE64`
- `KEY_STORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

**Workflow step:**
```yaml
- name: Decode Keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

- name: Build Signed APK
  run: flutter build apk --release
  env:
    KEY_STORE_PASSWORD: ${{ secrets.KEY_STORE_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

**`android/app/build.gradle` signing config:**
```groovy
signingConfigs {
    release {
        storeFile file("keystore.jks")
        storePassword System.getenv("KEY_STORE_PASSWORD")
        keyAlias System.getenv("KEY_ALIAS")
        keyPassword System.getenv("KEY_PASSWORD")
    }
}
```

**Source:** https://docs.flutter.dev/deployment/android#signing-the-app

### 7. Coverage Enforcement in PRs

```yaml
- name: Enforce coverage threshold
  uses: VeryGoodOpenSource/very_good_coverage@v3
  with:
    path: coverage/lcov.info
    min_coverage: 80
```

Posts a comment on the PR if coverage falls below the threshold.

**Source:** https://github.com/VeryGoodOpenSource/very_good_coverage

### 8. Branch Protection Rules

**Recommended settings for `main` branch** (Settings → Branches → Add rule):

1. Require a pull request before merging (prevents direct pushes to main)
2. Require status checks to pass — add CI job names as required checks
3. Require branches to be up to date before merging
4. Require conversation resolution before merging
5. Dismiss stale PR approvals when new commits are pushed
6. Do not allow bypassing rules (applies to admins too)

Required check names must match the job `name:` field in the workflow YAML exactly (e.g., `ci` or `Flutter CI / ci`).

**Source:** https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

---

## Part B: Testing Practices

### 1. Unit Testing Business Logic

```dart
// test/models/expense_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Expense model', () {
    test('toMap and fromMap round-trip', () {
      final original = Expense(
        id: 1,
        item: 'Coffee',
        category: 'Food',
        cost: 4.50,
        date: DateTime(2024, 3, 1),
      );
      final map = original.toMap();
      final restored = Expense.fromMap(map);
      expect(restored, equals(original));
    });

    test('rejects negative cost', () {
      expect(
        () => Expense(item: 'X', category: 'Y', cost: -1.0, date: DateTime.now()),
        throwsArgumentError,
      );
    });
  });
}
```

### 2. Widget Testing

```dart
// test/widgets/expense_list_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/expense_list_tile.dart';

void main() {
  testWidgets('shows formatted amount and category', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpenseListTile(
            amount: 42.00,
            category: 'Food',
            date: '2024-03-01',
          ),
        ),
      ),
    );

    expect(find.text('\$42.00'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('delete button triggers callback', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseListTile(
            amount: 10.0,
            category: 'Food',
            date: '2024-03-01',
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();
    expect(deleted, isTrue);
  });
}
```

**`pump` vs `pumpAndSettle`:**

| Method | When to use |
|---|---|
| `pump()` | After synchronous `setState` calls — triggers one frame rebuild |
| `pump(Duration)` | Advance animations by a specific duration |
| `pumpAndSettle()` | After async operations, page transitions, or animations — pumps until no pending frames |

### 3. Integration Testing (integration_test)

The `integration_test` package (part of Flutter SDK since 2.5) runs tests inside the app process:

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add expense end-to-end', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount_field')), '25.50');
    await tester.enterText(find.byKey(const Key('description_field')), 'Lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
  });
}
```

Run on a connected device or emulator:
```bash
flutter test integration_test/
```

**Source:** https://docs.flutter.dev/testing/integration-tests

### 4. Mocking: mocktail (Recommended)

`mocktail` requires no code generation (unlike `mockito`):

```dart
// pubspec.yaml dev_dependencies: mocktail: ^1.0.x

import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepo;

  setUp(() => mockRepo = MockExpenseRepository());

  test('notifier loads expenses on build', () async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => [testExpense]);

    final container = ProviderContainer(overrides: [
      expenseRepositoryProvider.overrideWithValue(mockRepo),
    ]);

    final expenses = await container.read(expenseNotifierProvider.future);
    expect(expenses, [testExpense]);
    verify(() => mockRepo.getAll()).called(1);
  });
}
```

**mocktail vs mockito:**
- `mocktail` — no `build_runner`, cleaner syntax, works with sealed classes
- `mockito` — requires `@GenerateMocks` + `build_runner`; use only if already in the codebase

**Source:** https://pub.dev/packages/mocktail

### 5. Testing SQLite with sqflite_ffi

The standard `sqflite` plugin requires a native device/emulator. For CI testing without a device, use `sqflite_ffi`:

```dart
// pubspec.yaml dev_dependencies: sqflite_ffi: ^2.3.x

import 'package:sqflite_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ExpenseRepository', () {
    late Database db;

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath, // fresh DB per test
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(createExpensesTableSql),
        ),
      );
    });

    tearDown(() => db.close());

    test('inserts and retrieves expense', () async {
      final repo = ExpenseRepository(db);
      await repo.insert(Expense(item: 'Coffee', category: 'Food', cost: 4.5, date: DateTime.now()));

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.item, 'Coffee');
    });
  });
}
```

**Note for CI:** Linux runners may need `libsqlite3-dev`:
```yaml
- run: sudo apt-get install -y libsqlite3-dev
```

**Source:** https://pub.dev/packages/sqflite_ffi

### 6. Coverage Targets

| Layer | Target | Rationale |
|---|---|---|
| Business logic / models | 90%+ | Pure Dart, easiest to test, highest ROI |
| Repository / data layer | 80%+ | Critical correctness, testable with sqflite_ffi |
| ViewModels / state | 80%+ | State transitions are pure logic |
| Widgets | 60–70% | Harder to test visually |
| Integration tests | Key user flows | Not measured in line coverage |

**Exclude generated files from coverage:**
```bash
lcov --remove coverage/lcov.info \
  '**/*.g.dart' \
  '**/*.freezed.dart' \
  '**/generated/**' \
  -o coverage/lcov_cleaned.info
```

### 7. What to Test for This Expense Tracker

**Unit tests (highest priority):**
- `Expense` model: `toMap`/`fromMap` round-trip, validation, `copyWith`
- `ExpenseRepository`: CRUD operations using `sqflite_ffi` in-memory DB
- Aggregate/summary calculations: total by category, monthly summaries
- `ExpenseNotifier`/`ExpenseCubit`: state transitions (initial → loading → loaded/error)

**Widget tests (medium priority):**
- `ExpenseListTile`: displays amount formatted correctly, calls `onDelete` callback
- `AddExpenseForm`: shows validation errors, calls `onSubmit` with correct data
- `ExpenseSummaryCard`: displays correct totals and breakdowns
- Empty state widget: shown when no expenses in the list

**Integration tests (low priority, happy paths only):**
- Add expense end-to-end
- Delete expense
- Filter by category
- Navigate between home, history, and form screens

**Skip testing:**
- Generated code (`.g.dart`, `.freezed.dart`)
- Flutter framework internals
- Trivial getters with no logic

---

## Sources

- https://docs.flutter.dev/deployment/cd
- https://docs.flutter.dev/testing/overview
- https://docs.flutter.dev/testing/integration-tests
- https://github.com/subosito/flutter-action
- https://github.com/softprops/action-gh-release
- https://github.com/googleapis/release-please-action
- https://github.com/googleapis/release-please
- https://github.com/codecov/codecov-action
- https://github.com/VeryGoodOpenSource/very_good_coverage
- https://github.com/ReactiveCircus/android-emulator-runner
- https://pub.dev/packages/mocktail
- https://pub.dev/packages/sqflite_ffi
- https://pub.dev/packages/integration_test
- https://www.conventionalcommits.org/en/v1.0.0/
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
