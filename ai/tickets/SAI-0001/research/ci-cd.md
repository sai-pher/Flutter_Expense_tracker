# Research: Flutter CI/CD with GitHub Actions

> **Ticket:** SAI-0001 – Phase 1 Research  
> **Topic:** GitHub Actions workflows, APK versioning & release, changelog generation, APK signing  
> **Sources:** GitHub Marketplace, official action READMEs, flutter.dev

---

## 1. Core GitHub Actions Workflow for Flutter

The canonical action for setting up Flutter in a GitHub Actions runner is **`subosito/flutter-action@v2`**.

**Source:** https://github.com/marketplace/actions/flutter-action

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  analyze-and-test:
    name: Analyze & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.5"   # pin exact version
          channel: stable
          cache: true                 # caches Flutter SDK
          pub-cache: true             # caches pub dependencies

      - name: Install SQLite (for sqflite_common_ffi)
        run: sudo apt-get install -y libsqlite3-0 libsqlite3-dev

      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage

      - name: Enforce coverage minimum
        uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: coverage/lcov.info
          min_coverage: 80
          exclude: "**/*.g.dart **/generated/**"

      - name: Post coverage comment to PR
        if: github.event_name == 'pull_request'
        uses: romeovs/lcov-reporter-action@v0.3.1
        with:
          lcov-file: coverage/lcov.info
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Flutter version pinning options

| Option | Usage |
|--------|-------|
| Exact version | `flutter-version: "3.41.5"` |
| Wildcard | `flutter-version: "3.x"` |
| From pubspec | `flutter-version-file: pubspec.yaml` |
| Latest stable | Omit `flutter-version`, set `channel: stable` |

---

## 2. APK Versioning

Flutter uses `version: MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`, mapping directly to Android:
- `versionName` = the `x.y.z` part
- `versionCode` = the `+N` build number

Example: `version: 1.2.3+45`

**Override at build time:**
```bash
flutter build apk \
  --build-name=1.2.3 \
  --build-number=45
```

**In GitHub Actions:**
```yaml
- name: Build versioned APK
  run: |
    VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
    BUILD_NUMBER=${{ github.run_number }}
    flutter build apk --release \
      --build-name=${VERSION%+*} \
      --build-number=$BUILD_NUMBER
```

- `github.run_number` is an ever-incrementing integer — ideal for `versionCode`
- `github.ref_name` on a tag push gives e.g. `v1.2.3`
- With `release-please` (see below), `pubspec.yaml`'s version is bumped automatically before the build

---

## 3. GitHub Releases with Attached APK Artifacts

### `softprops/action-gh-release@v2` — creating releases and attaching files

```yaml
- name: Create GitHub Release
  uses: softprops/action-gh-release@v2
  if: github.ref_type == 'tag'
  with:
    files: build/app/outputs/flutter-apk/app-release.apk
    generate_release_notes: true   # auto-notes from merged PRs
  permissions:
    contents: write
```

Trigger on version tags:
```yaml
on:
  push:
    tags:
      - "v*.*.*"
```

**Source:** https://github.com/marketplace/actions/gh-release

### `actions/upload-artifact@v4` — inter-job sharing

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: app-release-apk
    path: build/app/outputs/flutter-apk/app-release.apk
    retention-days: 5              # 90 day max; 5 is a reasonable CI TTL
```

Retrieve in a subsequent job:
```yaml
- uses: actions/download-artifact@v4
  with:
    name: app-release-apk
```

**Source:** https://github.com/marketplace/actions/upload-a-build-artifact

---

## 4. Changelog Generation: release-please

**`googleapis/release-please-action@v4`** is the recommended tool for automated versioning and changelogs. It:
1. Parses git history for Conventional Commits
2. Maintains an always-open “Release PR” accumulating unreleased changes
3. On merge of the Release PR: bumps version in tracked files, writes `CHANGELOG.md`, creates a GitHub Release with a tag

**Source:** https://github.com/marketplace/actions/release-please-action

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main, master]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          release-type: dart          # handles pubspec.yaml version bumping
          token: ${{ secrets.GITHUB_TOKEN }}

  build-and-attach:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ needs.release-please.outputs.tag_name }}
          files: build/app/outputs/flutter-apk/app-release.apk
```

### Conventional Commits → Semver mapping

| Commit prefix | Semver bump | Example |
|--------------|-------------|--------|
| `fix:` | patch (0.0.X) | `fix: correct date formatting` |
| `feat:` | minor (0.X.0) | `feat: add export to CSV` |
| `feat!:` / `BREAKING CHANGE:` footer | major (X.0.0) | `feat!: remove legacy DB schema` |
| `chore:`, `docs:`, `refactor:`, `test:` | none (changelog only) | no version bump |

**Squash-merge is strongly recommended** to keep a clean linear history for release-please to parse.

**Forcing a version:** Add a commit with body `Release-As: 2.0.0`.

---

## 5. APK Signing via GitHub Secrets

**Step 1 — Encode keystore:**
```bash
openssl base64 < my-release-key.jks | tr -d '\n' > signing_key.base64.txt
```

**Step 2 — Store as GitHub Secrets:**
- `SIGNING_KEY` — base64-encoded keystore
- `KEY_ALIAS` — key alias
- `KEY_STORE_PASSWORD` — keystore password
- `KEY_PASSWORD` — key password

**Step 3 — Sign in workflow:**

```yaml
- run: flutter build apk --release

- name: Sign APK
  uses: r0adkll/sign-android-release@v1
  id: sign_app
  with:
    releaseDirectory: build/app/outputs/flutter-apk
    signingKeyBase64: ${{ secrets.SIGNING_KEY }}
    alias: ${{ secrets.KEY_ALIAS }}
    keyStorePassword: ${{ secrets.KEY_STORE_PASSWORD }}
    keyPassword: ${{ secrets.KEY_PASSWORD }}
  env:
    BUILD_TOOLS_VERSION: "34.0.0"

- uses: softprops/action-gh-release@v2
  with:
    files: ${{ steps.sign_app.outputs.signedReleaseFile }}
```

**Source:** https://github.com/marketplace/actions/sign-android-release

---

## 6. Branch Protection Rules

Recommended settings for `main`/`master` (GitHub → Settings → Branches):

| Setting | Value |
|---------|-------|
| Require pull request before merging | Enabled |
| Required approving reviews | 1 |
| Require status checks to pass | Enabled |
| Required status checks | `Analyze & Test`, `build` |
| Require branches to be up to date | Enabled |
| Require conversation resolution | Enabled |
| Allow bypassing settings | Disabled |

**Job name = check name:** GitHub uses the job `name:` field as the status check identifier in branch protection.

```yaml
jobs:
  analyze-and-test:     # shows as "Analyze & Test" if name: is set
    name: Analyze & Test
```

---

## 7. Complete Production Workflow

```yaml
# .github/workflows/ci.yml  — runs on every PR and push
name: CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  analyze-and-test:
    name: Analyze & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.5"
          channel: stable
          cache: true
          pub-cache: true
      - run: sudo apt-get install -y libsqlite3-0 libsqlite3-dev
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: coverage/lcov.info
          min_coverage: 80
      - if: github.event_name == 'pull_request'
        uses: romeovs/lcov-reporter-action@v0.3.1
        with:
          lcov-file: coverage/lcov.info
          github-token: ${{ secrets.GITHUB_TOKEN }}

# .github/workflows/release.yml  — triggers on merge to main
name: Release
on:
  push:
    branches: [main, master]
permissions:
  contents: write
  pull-requests: write
jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          release-type: dart
          token: ${{ secrets.GITHUB_TOKEN }}

  build-sign-release:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.5"
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: r0adkll/sign-android-release@v1
        id: sign_app
        with:
          releaseDirectory: build/app/outputs/flutter-apk
          signingKeyBase64: ${{ secrets.SIGNING_KEY }}
          alias: ${{ secrets.KEY_ALIAS }}
          keyStorePassword: ${{ secrets.KEY_STORE_PASSWORD }}
          keyPassword: ${{ secrets.KEY_PASSWORD }}
        env:
          BUILD_TOOLS_VERSION: "34.0.0"
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ needs.release-please.outputs.tag_name }}
          files: ${{ steps.sign_app.outputs.signedReleaseFile }}
```

---

## Sources

| Topic | URL |
|-------|-----|
| `subosito/flutter-action` | https://github.com/marketplace/actions/flutter-action |
| `googleapis/release-please-action` | https://github.com/marketplace/actions/release-please-action |
| `softprops/action-gh-release` | https://github.com/marketplace/actions/gh-release |
| `r0adkll/sign-android-release` | https://github.com/marketplace/actions/sign-android-release |
| `actions/upload-artifact` | https://github.com/marketplace/actions/upload-a-build-artifact |
| `VeryGoodOpenSource/very_good_coverage` | https://github.com/VeryGoodOpenSource/very_good_coverage |
| Conventional Commits spec | https://www.conventionalcommits.org/ |
