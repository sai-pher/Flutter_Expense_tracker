# CI/CD Proposal: GitHub Actions for Flutter Expense Tracker

> Based on research in `docs/research/03-ci-cd-testing.md`.
> Target: Automated quality gates on every PR, versioned APK artifacts on every release.

---

## Overview

Three workflows, each with a single responsibility:

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push to any branch; PR to `main` | Format, analyze, test, coverage |
| `release-please.yml` | Push to `main` | Auto-create Release PR + CHANGELOG |
| `release.yml` | Push of `v*.*.*` tag | Build signed APK + create GitHub Release |

---

## Workflow 1: CI (Quality Gates)

**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    name: Flutter CI
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
          cache: true

      - name: Install SQLite (for sqflite_ffi tests)
        run: sudo apt-get install -y libsqlite3-dev

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code (build_runner)
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Exclude generated files from coverage
        run: |
          sudo apt-get install -y lcov
          lcov --remove coverage/lcov.info \
            '**/*.g.dart' \
            '**/*.freezed.dart' \
            -o coverage/lcov_cleaned.info

      - name: Enforce coverage threshold
        uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: coverage/lcov_cleaned.info
          min_coverage: 80

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: coverage/lcov_cleaned.info
        if: always()
```

### Notes

- `concurrency` cancels in-progress runs on the same branch when new commits are pushed (saves CI minutes).
- `libsqlite3-dev` is required for `sqflite_ffi` on Linux runners.
- The `build_runner` step regenerates `.g.dart` and `.freezed.dart` files in CI rather than requiring them to be committed. This keeps the repository cleaner but adds ~30-60s to CI time. An alternative is to commit generated files and add a `--check` step.
- Coverage is enforced at 80% minimum; this threshold should be raised as the test suite matures.

---

## Workflow 2: release-please (Automated Versioning)

**File:** `.github/workflows/release-please.yml`

```yaml
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    name: Release Please
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          release-type: dart
          token: ${{ secrets.GITHUB_TOKEN }}
```

**Configuration file:** `release-please-config.json` (project root)

```json
{
  "packages": {
    ".": {
      "release-type": "dart",
      "bump-minor-pre-major": true,
      "changelog-sections": [
        {"type": "feat", "section": "Features"},
        {"type": "fix", "section": "Bug Fixes"},
        {"type": "perf", "section": "Performance"},
        {"type": "refactor", "section": "Code Refactoring"},
        {"type": "deps", "section": "Dependencies", "hidden": false}
      ]
    }
  }
}
```

**`.release-please-manifest.json`** (project root):
```json
{".": "1.0.0"}
```

### How It Works

1. Developers write commits using Conventional Commits format (e.g., `feat: add category filter`)
2. On every push to `main`, `release-please` scans commits since the last release
3. If releasable commits exist, it opens or updates a "Release PR" that:
   - Bumps the version in `pubspec.yaml`
   - Generates/updates `CHANGELOG.md`
4. When the Release PR is merged, `release-please` creates a `v1.x.x` tag and a GitHub Release
5. The `v*.*.*` tag triggers Workflow 3 (APK build)

### Conventional Commit Reference

```
feat: add expense categories filter        → minor bump (1.X.0)
fix: correct pie chart color assignment   → patch bump (1.0.X)
docs: update README with setup steps      → no release
chore: update dependencies                → no release
refactor: extract repository layer        → no release
feat!: change DB schema (migration req'd) → major bump (X.0.0)
```

---

## Workflow 3: Build and Release APK

**File:** `.github/workflows/release.yml`

```yaml
name: Release APK

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  build:
    name: Build and Release APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks
        if: ${{ secrets.KEYSTORE_BASE64 != '' }}

      - name: Build signed APK
        run: |
          flutter build apk --release \
            --build-name=${GITHUB_REF_NAME#v} \
            --build-number=${{ github.run_number }}
        env:
          KEY_STORE_PASSWORD: ${{ secrets.KEY_STORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
            build/app/outputs/flutter-apk/expense-tracker-${{ github.ref_name }}.apk

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: build/app/outputs/flutter-apk/expense-tracker-${{ github.ref_name }}.apk
          generate_release_notes: true
          body: |
            See [CHANGELOG.md](CHANGELOG.md) for details.
```

### Android Signing Setup

**Prerequisites (one-time setup):**

1. Generate or obtain the Android signing keystore (`.jks` file)
2. Encode to base64:
   ```bash
   base64 -w 0 release-keystore.jks
   ```
3. Add the following GitHub Secrets (Settings → Secrets → Actions):
   - `KEYSTORE_BASE64` — the base64 string
   - `KEY_STORE_PASSWORD` — keystore password
   - `KEY_ALIAS` — key alias
   - `KEY_PASSWORD` — key password

4. Update `android/app/build.gradle` signing config:
   ```groovy
   signingConfigs {
       release {
           storeFile file("keystore.jks")
           storePassword System.getenv("KEY_STORE_PASSWORD") ?: ""
           keyAlias System.getenv("KEY_ALIAS") ?: ""
           keyPassword System.getenv("KEY_PASSWORD") ?: ""
       }
   }
   buildTypes {
       release {
           signingConfig signingConfigs.release
       }
   }
   ```

5. Add `keystore.jks` to `.gitignore`

**Without signing secrets:** The workflow includes an `if` condition — if `KEYSTORE_BASE64` is not set, the keystore decode step is skipped and Flutter builds an unsigned APK (useful for testing the workflow before signing is configured).

---

## Branch Protection Setup

**Settings → Branches → Add rule → Branch name pattern: `main`**

Recommended settings:
- [x] Require a pull request before merging
- [x] Require approvals: 1 (adjust for team size)
- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require status checks to pass before merging
  - Add required check: `Flutter CI` (must match the `name:` field in `ci.yml` job)
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Do not allow bypassing the above settings

**Note:** The required status check name (`Flutter CI`) only appears in the dropdown after the CI workflow has run at least once on a PR targeting `main`.

---

## Codecov Setup

1. Sign up at https://app.codecov.io/ using GitHub OAuth
2. Add the `expense_tracker` repository
3. Copy the `CODECOV_TOKEN` from the Codecov dashboard
4. Add it as a GitHub Secret: `CODECOV_TOKEN`

Codecov will then post coverage delta reports as PR comments:
```
Coverage: 82.4% (+5.2%) compared to main
```

---

## Full Pipeline Visualization

```
Developer writes code
        │
        ▼
git commit -m "feat: add category filter"
        │
        ▼
Push to feature branch
        │
        ▼
CI workflow runs automatically
  ├── dart format --check
  ├── flutter analyze --fatal-infos
  ├── flutter test --coverage
  ├── coverage >= 80% check
  └── Codecov comment on PR
        │
        ▼ (all checks pass)
PR opened/updated → Code review
        │
        ▼ (approved + all checks pass)
Merge to main
        │
        ├──► release-please opens/updates Release PR
        │         (bumps pubspec.yaml version, updates CHANGELOG.md)
        │
        ▼ (Release PR merged by developer)
v1.X.X tag created automatically
        │
        ▼
release.yml triggered by tag
  ├── flutter build apk --release
  ├── APK renamed to expense-tracker-v1.X.X.apk
  └── GitHub Release created with APK + release notes
```

---

## Incremental Adoption Plan

Not everything needs to be set up at once. Recommended order:

1. **Start with `ci.yml`** (no secrets required) — immediate value from format/analyze/test gates
2. **Add branch protection** requiring the CI check — enforces quality before `release-please`
3. **Add `release-please.yml`** — start using conventional commits; Release PRs will accumulate
4. **Set up Codecov** — adds coverage visibility on PRs
5. **Set up signing secrets + `release.yml`** — once signing is configured, release automation is complete

---

## Sources

- https://github.com/subosito/flutter-action
- https://github.com/googleapis/release-please-action
- https://github.com/softprops/action-gh-release
- https://github.com/VeryGoodOpenSource/very_good_coverage
- https://github.com/codecov/codecov-action
- https://docs.flutter.dev/deployment/android#signing-the-app
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- https://www.conventionalcommits.org/en/v1.0.0/
