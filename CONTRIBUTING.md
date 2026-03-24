# Contributing

Thank you for taking the time to contribute to Expense Tracker. This document describes the conventions and workflow expected for all contributions.

---

## Development Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) – latest stable channel (`flutter channel stable && flutter upgrade`)
- Android Studio or VS Code with the Flutter/Dart plugins
- An Android emulator or physical device for testing

## Getting Started

```bash
# Clone the repo
git clone https://github.com/sai-pher/flutter_expense_tracker.git
cd flutter_expense_tracker

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run all tests
flutter test
```

---

## Branching Strategy

| Branch | Purpose |
|---|---|
| `master` | Stable, production-ready code. Protected. |
| `feature/<ticket-id>-<short-description>` | New features |
| `fix/<ticket-id>-<short-description>` | Bug fixes |
| `chore/<ticket-id>-<short-description>` | Tooling, deps, CI, docs |
| `claude/<description>` | AI-agent work branches |

Always branch from `master`. Open a pull request to merge back.

---

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `style`, `ci`

Examples:
```
feat(expenses): add category filter to history page
fix(db): handle null cost value on insert
chore(deps): upgrade sqflite to 2.3.x
```

---

## Pull Requests

- Fill in the pull request template completely.
- Link to the relevant ticket/issue.
- Ensure all tests pass before requesting review.
- Keep PRs focused – one concern per PR.
- Request review from a CODEOWNER if your changes touch core modules.

---

## Code Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Run `flutter analyze` before pushing – all warnings should be resolved.
- Run `dart format .` to auto-format code.
- Do not leave `TODO` comments or `print()` statements in production paths.

---

## Testing

- Write tests for all new business logic.
- Unit tests live in `test/` mirroring the `lib/` structure.
- Widget tests for non-trivial UI components.
- Aim to keep code coverage above 70% for the data layer.
- Run `flutter test --coverage` to verify locally.

---

## AI-Driven Development

This repo supports AI-agent contributions via Claude Code. See `CLAUDE.md` for the conventions agents should follow.
