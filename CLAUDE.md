# CLAUDE.md – AI Development Guide

This file provides context for Claude Code (and other AI coding agents) working in this repository.

---

## Project Summary

**Expense Tracker** is a local-only Flutter mobile app that lets users record and analyse personal expenses. Data is persisted on-device with SQLite. There is no backend or cloud component.

---

## Key Conventions

### Branching
- Develop on a dedicated branch: `claude/<description>-<id>`
- Never push directly to `master`
- Open a pull request for all changes

### Commits
- Use Conventional Commits: `feat|fix|chore|docs|test|refactor(scope): summary`
- Commit at logical checkpoints — do not squash all work into one giant commit
- Push progress commits regularly so work is reviewable and resumable

### Code Quality
- Run `flutter analyze` — zero warnings expected
- Run `dart format .` before committing Dart files
- No `print()` in production code — use a proper logger if needed
- No unresolved `TODO` comments in merged code

### Testing
- Add/update tests for any logic changes
- Tests live in `test/` mirroring `lib/` structure
- Run `flutter test` before pushing

---

## Architecture Pointers

- See `architecture.md` for current app structure and the direction of travel.
- See `ai/tickets/SAI-0001/analysis/` for modernisation proposals.
- Data layer: `lib/db_handler/` — `DBHandler` singleton + models
- UI layer: `lib/pages/` (screens) + `lib/widgets/` (reusable components)
- Entry point: `lib/main.dart`

---

## Work Thread Tracking

Work threads are tracked in `ai/tickets/<ticket-id>/README.md`. Each ticket has:
- A summary of what the thread covers
- A checklist of tasks with phase grouping
- Research docs in `ai/tickets/<ticket-id>/research/`
- Analysis/proposal docs in `ai/tickets/<ticket-id>/analysis/`

Always update the checklist as tasks are completed.

---

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug)
flutter run

# Analyze code
flutter analyze

# Format code
dart format .

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Build release APK
flutter build apk --release
```

---

## Current Known Issues (pre-modernisation)

- Flutter/Dart SDK is very old (`>=2.1.0 <3.0.0`) — no null safety
- `charts_flutter` package is abandoned — must be replaced
- Deprecated Material widgets in use (`FlatButton`, `RaisedButton`)
- No state management library — direct `setState` + direct DB calls from widgets
- No linting config (`analysis_options.yaml` missing)
- Android build config uses deprecated `jcenter()` and outdated Gradle/Kotlin versions
- No CI/CD pipeline

Do not make changes that depend on null safety until the Flutter upgrade ticket is complete.
