# Expense Tracker

A local-only mobile application for recording and analysing personal expenses.

> **Status:** Active development — currently undergoing modernisation to latest stable Flutter. See [SAI-0001](ai/tickets/SAI-0001/README.md) for the current work thread.

---

## Features

- Record individual expenses with item name, category, and cost
- View spending analytics broken down by category
- Pie chart visualisation of category spend
- All data stored locally on-device (SQLite) — no account or internet required

## Platform

- Android (primary)
- iOS (structure present, not actively tested)

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) – latest stable
- Android Studio or VS Code with Flutter/Dart plugins
- An Android emulator or physical device

### Setup

```bash
git clone https://github.com/sai-pher/flutter_expense_tracker.git
cd flutter_expense_tracker
flutter pub get
flutter run
```

### Run Tests

```bash
flutter test
```

---

## Project Structure

```
lib/
├── main.dart              # App entry point & route table
├── app/                   # App-wide constants
├── db_handler/            # SQLite data layer (models + handler)
├── pages/                 # Screen-level widgets
wieldy/widgets/            # Reusable widget components
test/                      # Unit and widget tests
ai/                        # AI-agent working documents & research
```

See [architecture.md](architecture.md) for a full architectural overview.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, commit conventions, and code style guidelines.

---

## Roadmap

- [ ] Upgrade to Flutter 3.x + Dart 3 (null safety)
- [ ] Replace deprecated `charts_flutter` with `fl_chart`
- [ ] Introduce proper state management (Riverpod/Bloc)
- [ ] CI/CD pipeline with GitHub Actions (APK build + release)
- [ ] Complete history page
- [ ] Expand test coverage
